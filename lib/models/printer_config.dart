class PrinterConfig {
  final String ip;
  final int port;
  final String user;
  final String label;

  const PrinterConfig({
    required this.ip,
    this.port = 9100,
    this.user = '',
    this.label = '',
  });

  bool get isConfigured => ip.trim().isNotEmpty && port > 0;

  bool matchesUser(String txUser) =>
      user.trim().isNotEmpty &&
      user.trim().toLowerCase() == txUser.trim().toLowerCase();
}
