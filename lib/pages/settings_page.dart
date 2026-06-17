import 'package:flutter/material.dart';

import '../models/printer_config.dart';
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
  final eventNameController = TextEditingController();
  final pollingController = TextEditingController();

  late final List<TextEditingController> ipControllers;
  late final List<TextEditingController> portControllers;
  late final List<TextEditingController> userControllers;
  late final List<TextEditingController> labelControllers;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    ipControllers =
        List.generate(AppSettings.maxPrinters, (_) => TextEditingController());
    portControllers =
        List.generate(AppSettings.maxPrinters, (_) => TextEditingController());
    userControllers =
        List.generate(AppSettings.maxPrinters, (_) => TextEditingController());
    labelControllers =
        List.generate(AppSettings.maxPrinters, (_) => TextEditingController());
    _load();
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    merchantCodeController.dispose();
    pollingController.dispose();
    for (final controller in ipControllers) {
      controller.dispose();
    }
    for (final controller in portControllers) {
      controller.dispose();
    }
    for (final controller in userControllers) {
      controller.dispose();
    }
    for (final controller in labelControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await widget.settingsService.load();
    apiKeyController.text = settings.apiKey;
    merchantCodeController.text = settings.merchantCode;
    pollingController.text = settings.pollingSeconds.toString();

    for (var i = 0; i < AppSettings.maxPrinters; i++) {
      final printer = settings.printers[i];
      ipControllers[i].text = printer.ip;
      portControllers[i].text = printer.port.toString();
      userControllers[i].text = printer.user;
      labelControllers[i].text = printer.label;
    }

    setState(() => loading = false);
  }

  List<PrinterConfig> _buildPrintersFromForm() {
    final printers = <PrinterConfig>[];
    for (var i = 0; i < AppSettings.maxPrinters; i++) {
      printers.add(PrinterConfig(
        ip: ipControllers[i].text.trim(),
        port: int.tryParse(portControllers[i].text.trim()) ?? 9100,
        user: userControllers[i].text.trim(),
        label: labelControllers[i].text.trim(),
      ));
    }
    return printers;
  }

  Future<void> _save() async {
    if (ipControllers[0].text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L’IP de l’imprimante 1 (par défaut) est obligatoire'),
        ),
      );
      return;
    }

    final settings = AppSettings(
      apiKey: apiKeyController.text,
      merchantCode: merchantCodeController.text,
      printers: _buildPrintersFromForm(),
      pollingSeconds: int.tryParse(pollingController.text) ?? 5,
    );
    await widget.settingsService.save(settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réglages enregistrés')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _testPrinter(int index) async {
    final ip = ipControllers[index].text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renseigne l’IP de l’imprimante ${index + 1}')),
      );
      return;
    }

    try {
      await PrinterService(
        ip: ip,
        port: int.tryParse(portControllers[index].text.trim()) ?? 9100,
        label: labelControllers[index].text.trim(),
      ).testPrint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test imprimante ${index + 1} envoyé')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur imprimante ${index + 1}: $e')),
      );
    }
  }

  Widget _buildPrinterCard(int index) {
    final isDefault = index == 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDefault
                  ? 'Imprimante 1 (par défaut)'
                  : 'Imprimante ${index + 1} (optionnelle)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipControllers[index],
              decoration: InputDecoration(
                labelText: isDefault ? 'IP imprimante *' : 'IP imprimante',
                hintText: '192.168.1.XX',
              ),
            ),
            TextField(
              controller: portControllers[index],
              decoration: const InputDecoration(labelText: 'Port imprimante'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: userControllers[index],
              decoration: InputDecoration(
                labelText: isDefault
                    ? 'Email utilisateur SumUp (optionnel)'
                    : 'Email utilisateur SumUp',
                hintText: 'ex: caisse@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: labelControllers[index],
              decoration: const InputDecoration(
                labelText: 'Libellé ticket',
                hintText: 'ex: Caisse Hervé ou 1',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _testPrinter(index),
              icon: const Icon(Icons.print),
              label: Text('Tester imprimante ${index + 1}'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
          Text(
            'Imprimantes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Associe chaque imprimante à un email SumUp. '
            'Si l’email de la transaction ne correspond à aucune imprimante, '
            'l’imprimante 1 est utilisée.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < AppSettings.maxPrinters; i++)
            _buildPrinterCard(i),
          const SizedBox(height: 8),
          TextField(
            controller: pollingController,
            decoration: const InputDecoration(
              labelText: 'Intervalle surveillance en secondes',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ),
      ),
    );
  }
}
