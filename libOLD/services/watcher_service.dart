import 'dart:async';
import '../models/local_order.dart';
import 'local_order_database.dart';
import 'printer_service.dart';
import 'product_summary_parser.dart';
import 'settings_service.dart';
import 'sumup_api_service.dart';

class WatcherResult {
  final int newPrintedCount;
  final String? error;

  const WatcherResult({this.newPrintedCount = 0, this.error});
}

class WatcherService {
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

    tick();
    _timer = Timer.periodic(
        Duration(seconds: settings.pollingSeconds), (_) => tick());
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
      final printer =
          PrinterService(ip: settings.printerIp, port: settings.printerPort);

      final transactions = await sumup.getRecentTransactions(limit: 10);
      transactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      var printed = 0;

      for (final tx in transactions) {
        print("isPrintable : " +
            tx.isPrintablePosPayment.toString() +
            " items: " +
            tx.productSummary.toString());
        if (!tx.isPrintablePosPayment) continue;
        if (await db.exists(tx.uniqueKey)) continue;

        final items = ProductSummaryParser.parse(tx.productSummary);
        if (items.isEmpty) continue;

        await printer.printOneTicketPerItem(items, tx);

        await db.upsertOrder(
          LocalOrder(
            id: tx.uniqueKey,
            transactionCode: tx.transactionCode,
            date: tx.timestamp,
            status: 'printed',
            amount: tx.amount,
            currency: tx.currency,
            productSummary: tx.productSummary ?? '',
            items: items,
          ),
        );

        printed++;
      }

      return WatcherResult(newPrintedCount: printed);
    } catch (e) {
      return WatcherResult(error: e.toString());
    } finally {
      _busy = false;
    }
  }
}
