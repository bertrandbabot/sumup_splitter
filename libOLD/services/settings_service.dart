import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String apiKey;
  final String merchantCode;
  final String printerIp;
  final int printerPort;
  final int pollingSeconds;

  const AppSettings({
    required this.apiKey,
    required this.merchantCode,
    required this.printerIp,
    required this.printerPort,
    required this.pollingSeconds,
  });

  bool get isConfigured =>
      apiKey.trim().isNotEmpty &&
      merchantCode.trim().isNotEmpty &&
      printerIp.trim().isNotEmpty &&
      printerPort > 0;
}

class SettingsService {
  static const _apiKey = 'sumup_api_key';
  static const _merchantCode = 'sumup_merchant_code';
  static const _printerIp = 'printer_ip';
  static const _printerPort = 'printer_port';
  static const _pollingSeconds = 'polling_seconds';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      apiKey: prefs.getString(_apiKey) ?? '',
      merchantCode: prefs.getString(_merchantCode) ?? '',
      printerIp: prefs.getString(_printerIp) ?? '192.168.1.50',
      printerPort: prefs.getInt(_printerPort) ?? 9100,
      pollingSeconds: prefs.getInt(_pollingSeconds) ?? 5,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKey, settings.apiKey.trim());
    await prefs.setString(_merchantCode, settings.merchantCode.trim());
    await prefs.setString(_printerIp, settings.printerIp.trim());
    await prefs.setInt(_printerPort, settings.printerPort);
    await prefs.setInt(_pollingSeconds, settings.pollingSeconds);
  }
}
