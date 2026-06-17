import 'package:flutter/material.dart';
import '../services/printer_service.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsPage({super.key, required this.settingsService});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final apiKeyController = TextEditingController();
  final merchantCodeController = TextEditingController();
  final printerIpController = TextEditingController();
  final printerPortController = TextEditingController();
  final pollingController = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await widget.settingsService.load();
    apiKeyController.text = settings.apiKey;
    merchantCodeController.text = settings.merchantCode;
    printerIpController.text = settings.printerIp;
    printerPortController.text = settings.printerPort.toString();
    pollingController.text = settings.pollingSeconds.toString();
    setState(() => loading = false);
  }

  Future<void> _save() async {
    final settings = AppSettings(
      apiKey: apiKeyController.text,
      merchantCode: merchantCodeController.text,
      printerIp: printerIpController.text,
      printerPort: int.tryParse(printerPortController.text) ?? 9100,
      pollingSeconds: int.tryParse(pollingController.text) ?? 5,
    );
    await widget.settingsService.save(settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réglages enregistrés')));
    Navigator.pop(context, true);
  }

  Future<void> _testPrinter() async {
    try {
      await PrinterService(
        ip: printerIpController.text.trim(),
        port: int.tryParse(printerPortController.text) ?? 9100,
      ).testPrint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test imprimante envoyé')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur imprimante: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: apiKeyController,
            decoration: const InputDecoration(labelText: 'Clé API SumUp'),
            obscureText: true,
          ),
          TextField(
            controller: merchantCodeController,
            decoration: const InputDecoration(labelText: 'Merchant Code SumUp'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: printerIpController,
            decoration: const InputDecoration(labelText: 'IP imprimante', hintText: '192.168.1.50'),
          ),
          TextField(
            controller: printerPortController,
            decoration: const InputDecoration(labelText: 'Port imprimante'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: pollingController,
            decoration: const InputDecoration(labelText: 'Intervalle surveillance en secondes'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _testPrinter,
            icon: const Icon(Icons.print),
            label: const Text('Tester imprimante'),
          ),
        ],
      ),
    );
  }
}
