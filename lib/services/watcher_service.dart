import 'dart:async';
import '../models/local_order.dart';
import 'local_order_database.dart';
import 'printer_service.dart';
import 'settings_service.dart';
import 'sumup_api_service.dart';

class WatcherResult {
  final int newPrintedCount;
  final String? error;

  const WatcherResult({this.newPrintedCount = 0, this.error});
}

class WatcherService {
  static const int historyLimit = 3;

  final LocalOrderDatabase db;
  Timer? _timer;
  bool _busy = false;

  WatcherService({required this.db});

  bool get isRunning => _timer != null;

  void start({
    required AppSettings settings,
    required void Function(WatcherResult result) onResult,
  }) {
    stop();
    Future<void> tick() async {
      final result = await checkOnce(settings);
      onResult(result);
    }

    Future<void> bootstrap() async {
      try {
        await seedRecentTransactions(settings);
      } catch (e) {
        print('[WATCHER] Erreur seed historique: $e');
        onResult(WatcherResult(error: e.toString()));
        return;
      }
      await tick();
    }

    bootstrap();
    _timer = Timer.periodic(
        Duration(seconds: settings.pollingSeconds), (_) => tick());
  }

  /// Marque les dernières transactions SumUp comme déjà vues, sans imprimer.
  Future<void> seedRecentTransactions(AppSettings settings) async {
    await _withBusyLock(() => _seedTransactions(settings));
  }

  /// Vide l'historique local puis protège contre la réimpression des dernières transactions.
  Future<void> resetHistory(AppSettings settings) async {
    await _withBusyLock(() async {
      await db.deleteAll();
      await _seedTransactions(settings);
    });
  }

  Future<void> _withBusyLock(Future<void> Function() action) async {
    while (_busy) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  Future<void> _seedTransactions(AppSettings settings) async {
    final sumup = SumupApiService(
      apiKey: settings.apiKey,
      merchantCode: settings.merchantCode,
    );

    print(
        '[WATCHER] Marquage des $historyLimit dernières transactions sans impression...');
    final transactions =
        await sumup.getRecentTransactions(limit: historyLimit);

    for (final tx in transactions) {
      if (!tx.isSuccessfulPayment) continue;
      if (await db.exists(tx.uniqueKey)) continue;

      await db.upsertOrder(
        LocalOrder(
          id: tx.uniqueKey,
          transactionCode: tx.transactionCode,
          date: tx.timestamp,
          status: 'seeded',
          amount: tx.amount,
          currency: tx.currency,
          items: const [],
          user: tx.user,
          printerIndex: settings.printerIndexForUser(tx.user),
        ),
      );
      print(
          '[WATCHER] Transaction ${tx.transactionCode} ignorée (déjà dans historique SumUp)');
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<WatcherResult> checkOnce(AppSettings settings) async {
    if (_busy) return const WatcherResult();
    _busy = true;

    try {
      final sumup = SumupApiService(
        apiKey: settings.apiKey,
        merchantCode: settings.merchantCode,
      );
      print('[WATCHER] Récupération des transactions SumUp...');
      final transactions =
          await sumup.getRecentTransactions(limit: historyLimit);
      transactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      var printed = 0;

      for (final tx in transactions) {
        print('----------------------------------------');
        print(
            '[WATCHER] Transaction ${tx.transactionCode} / ${tx.status} / ${tx.paymentType} / ${tx.amount} ${tx.currency}');

        if (!tx.isSuccessfulPayment) {
          print(
              '[WATCHER] Ignorée: transaction non SUCCESSFUL/PAYMENT ou code vide');
          continue;
        }

        if (await db.exists(tx.uniqueKey)) {
          print('[WATCHER] Ignorée: déjà traitée en SQLite');
          continue;
        }

        final receipt =
            await sumup.getReceiptByTransactionCode(tx.transactionCode);
        final products = receipt.products;

        if (products.isEmpty) {
          print('[WATCHER] Aucun produit dans le reçu, commande non imprimée');
          continue;
        }

        final printerIndex = settings.printerIndexForUser(tx.user);
        final target = settings.printers[printerIndex];
        final printer = PrinterService(
          ip: target.ip,
          port: target.port,
          label: target.label,
        );

        print(
            '[WATCHER] Impression de ${products.length} ligne(s) produit(s) sur ${target.ip} (index=$printerIndex, user=${tx.user}, label=${target.label})...');
        await printer.printOneTicketPerItem(products, tx);

        await db.upsertOrder(
          LocalOrder(
              id: tx.uniqueKey,
              transactionCode: tx.transactionCode,
              receiptNo: receipt.receiptNo,
              date: receipt.timestamp,
              status: 'printed',
              paymentType: receipt.paymentType.isNotEmpty
                  ? receipt.paymentType
                  : tx.paymentType,
              amount: receipt.amount > 0 ? receipt.amount : tx.amount,
              currency:
                  receipt.currency.isNotEmpty ? receipt.currency : tx.currency,
              items: products,
              user: tx.user,
              printerIndex: printerIndex),
        );

        printed++;
        print(
            '[WATCHER] Commande ${tx.transactionCode} traitée et sauvegardée');
      }

      return WatcherResult(newPrintedCount: printed);
    } catch (e) {
      print('[WATCHER] Erreur: $e');
      return WatcherResult(error: e.toString());
    } finally {
      _busy = false;
    }
  }
}
