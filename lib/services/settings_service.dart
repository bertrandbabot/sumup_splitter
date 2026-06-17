import 'package:shared_preferences/shared_preferences.dart';

import '../models/printer_config.dart';

class AppSettings {
  static const maxPrinters = 4;

  final String apiKey;
  final String merchantCode;
  final List<PrinterConfig> printers;
  final int pollingSeconds;

  const AppSettings({
    required this.apiKey,
    required this.merchantCode,
    required this.printers,
    required this.pollingSeconds,
  });

  PrinterConfig get defaultPrinter => printers.first;

  int printerIndexForUser(String txUser) {
    for (var i = 0; i < printers.length; i++) {
      if (printers[i].isConfigured && printers[i].matchesUser(txUser)) {
        return i;
      }
    }
    return 0;
  }

  PrinterConfig printerForUser(String txUser) =>
      printers[printerIndexForUser(txUser)];

  bool get isConfigured =>
      apiKey.trim().isNotEmpty &&
      merchantCode.trim().isNotEmpty &&
      defaultPrinter.isConfigured;
}

class SettingsService {
  static const _apiKey = 'sumup_api_key';
  static const _merchantCode = 'sumup_merchant_code';
  static const _pollingSeconds = 'polling_seconds';

  // Imprimante 1 : clés historiques (rétrocompatibilité)
  static const _printerIp = 'printer_ip';
  static const _printerPort = 'printer_port';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    final printers = <PrinterConfig>[
      PrinterConfig(
        ip: prefs.getString(_printerIp) ?? '192.168.1.50',
        port: prefs.getInt(_printerPort) ?? 9100,
        user: prefs.getString('printer_user_0') ?? '',
        label: prefs.getString('printer_label_0') ?? '',
      ),
    ];

    for (var i = 1; i < AppSettings.maxPrinters; i++) {
      printers.add(PrinterConfig(
        ip: prefs.getString('printer_ip_$i') ?? '',
        port: prefs.getInt('printer_port_$i') ?? 9100,
        user: prefs.getString('printer_user_$i') ?? '',
        label: prefs.getString('printer_label_$i') ?? '',
      ));
    }

    return AppSettings(
      apiKey: prefs.getString(_apiKey) ?? '',
      merchantCode: prefs.getString(_merchantCode) ?? '',
      printers: printers,
      pollingSeconds: prefs.getInt(_pollingSeconds) ?? 5,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKey, settings.apiKey.trim());
    await prefs.setString(_merchantCode, settings.merchantCode.trim());
    await prefs.setInt(_pollingSeconds, settings.pollingSeconds);

    final first = settings.printers.first;
    await prefs.setString(_printerIp, first.ip.trim());
    await prefs.setInt(_printerPort, first.port);
    await prefs.setString('printer_user_0', first.user.trim());
    await prefs.setString('printer_label_0', first.label.trim());

    for (var i = 1; i < AppSettings.maxPrinters; i++) {
      if (i < settings.printers.length &&
          settings.printers[i].ip.trim().isNotEmpty) {
        final printer = settings.printers[i];
        await prefs.setString('printer_ip_$i', printer.ip.trim());
        await prefs.setInt('printer_port_$i', printer.port);
        await prefs.setString('printer_user_$i', printer.user.trim());
        await prefs.setString('printer_label_$i', printer.label.trim());
      } else {
        await prefs.remove('printer_ip_$i');
        await prefs.remove('printer_port_$i');
        await prefs.remove('printer_user_$i');
        await prefs.remove('printer_label_$i');
      }
    }
  }
}
