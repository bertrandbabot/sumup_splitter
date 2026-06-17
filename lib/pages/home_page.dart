import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:sumup_ticket_splitter/models/sumup_transaction.dart';
import '../models/local_order.dart';
import '../services/local_order_database.dart';
import '../services/printer_service.dart';
import '../services/settings_service.dart';
import '../services/watcher_service.dart';
import '../widgets/order_card.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final settingsService = SettingsService();
  final db = LocalOrderDatabase();

  late final watcher = WatcherService(db: db);

  AppSettings? settings;

  List<LocalOrder> orders = [];

  String statusText = 'Chargement...';

  bool loading = true;

  @override
  void initState() {
    super.initState();

    _startup();
  }

  @override
  void dispose() {
    watcher.stop();

    super.dispose();
  }

  Future<void> _startup() async {
    // Initialise app
    await _init();

    // Ignore optimisation batterie
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();

    // Démarre foreground service
    await FlutterForegroundTask.startService(
      serviceId: 100,
      notificationTitle: 'Surveillance SumUp',
      notificationText: 'Application active',
      callback: startCallback,
    );

    print('[FOREGROUND] Service démarré');

    // Lance watcher automatiquement
    if (settings != null && settings!.isConfigured) {
      _startWatcher();
    }
  }

  Future<void> _init() async {
    settings = await settingsService.load();

    await _loadOrders();

    setState(() {
      loading = false;

      statusText = settings!.isConfigured ? 'Prêt' : 'Configuration requise';
    });
  }

  Future<void> _loadOrders() async {
    final result = await db.getOrders();

    setState(() => orders = result);
  }

  void _startWatcher() {
    final currentSettings = settings;

    if (currentSettings == null || !currentSettings.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configure d’abord SumUp et l’imprimante',
          ),
        ),
      );

      return;
    }

    watcher.start(
      settings: currentSettings,
      onResult: (result) async {
        if (result.error != null) {
          setState(() {
            statusText = 'Erreur: ${result.error}';
          });
        } else if (result.newPrintedCount > 0) {
          setState(() {
            statusText = '${result.newPrintedCount} commande(s) imprimée(s)';
          });

          await _loadOrders();
        } else {
          setState(() {
            statusText = 'Surveillance active';
          });
        }
      },
    );

    setState(() {
      statusText = 'Surveillance active';
    });
  }

  void _stopWatcher() {
    watcher.stop();

    setState(() {
      statusText = 'Surveillance arrêtée';
    });
  }

  Future<void> _checkOnce() async {
    final currentSettings = settings;

    if (currentSettings == null || !currentSettings.isConfigured) {
      return;
    }

    setState(() {
      statusText = 'Vérification...';
    });

    final result = await watcher.checkOnce(currentSettings);

    if (result.error != null) {
      setState(() {
        statusText = 'Erreur: ${result.error}';
      });
    } else {
      setState(() {
        statusText = '${result.newPrintedCount} nouvelle(s) commande(s)';
      });

      await _loadOrders();
    }
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          settingsService: settingsService,
        ),
      ),
    );

    if (changed == true) {
      settings = await settingsService.load();

      if (watcher.isRunning) {
        _startWatcher();
      }

      setState(() {});
    }
  }

  Future<void> _reprint(LocalOrder order) async {
    final currentSettings = settings;

    if (currentSettings == null || !currentSettings.isConfigured) {
      return;
    }

    try {
      await PrinterService(
        ip: currentSettings.printerIp,
        port: currentSettings.printerPort,
      ).printOneTicketPerItem(
        order.items,
        SumupTransaction(
          id: order.id,
          transactionCode: order.transactionCode,
          timestamp: order.date,
          status: order.status,
          paymentType: order.paymentType,
          type: "POS",
          amount: order.amount,
          currency: "EUR",
          user: order.user,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande réimprimée'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur réimpression: $e',
          ),
        ),
      );
    }
  }

  Future<void> _clearHistory() async {
    await db.deleteAll();

    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final printedOrders = orders.where((o) => o.isPrinted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SumUp Ticket Splitter'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: watcher.isRunning ? null : _startWatcher,
                          icon: const Icon(
                            Icons.play_arrow,
                          ),
                          label: const Text(
                            'Démarrer',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: watcher.isRunning ? _stopWatcher : null,
                          icon: const Icon(
                            Icons.stop,
                          ),
                          label: const Text(
                            'Arrêter',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _checkOnce,
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label: const Text(
                            'Vérifier maintenant',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _loadOrders,
                          icon: const Icon(
                            Icons.list,
                          ),
                          label: const Text(
                            'Rafraîchir liste',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearHistory,
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                          label: const Text(
                            'Vider historique',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: printedOrders.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune commande traitée',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: printedOrders.length,
                    itemBuilder: (context, index) {
                      final order = printedOrders[index];

                      return OrderCard(
                        order: order,
                        onReprint: () => _reprint(order),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(
    MyTaskHandler(),
  );
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(
    DateTime timestamp,
    TaskStarter starter,
  ) async {
    print('[FOREGROUND] onStart');
  }

  @override
  Future<void> onRepeatEvent(
    DateTime timestamp,
  ) async {
    print('[FOREGROUND] Tick');
  }

  @override
  Future<void> onDestroy(
    DateTime timestamp,
  ) async {
    print('[FOREGROUND] Destroy');
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}
