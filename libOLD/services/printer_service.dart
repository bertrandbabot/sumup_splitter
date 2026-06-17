import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:sumup_ticket_splitter/models/sumup_transaction.dart';
import '../models/sumup_receipt_item.dart';

class PrinterService {
  final String ip;
  final int port;

  const PrinterService({
    required this.ip,
    this.port = 9100,
  });

  Future<void> testPrint() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final bytes = <int>[];

    bytes.addAll(generator.reset());
    bytes.addAll(generator.text(
      'TEST IMPRESSION',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut(mode: PosCutMode.full));

    await _send(bytes);
  }

  Future<void> printOneTicketPerItem(
      List<SumupReceiptItem> items, SumupTransaction tx) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    for (final item in items) {
      print("------- TRANSACTION : " +
          tx.transactionCode +
          " -- ARTICLE : " +
          item.name);
      for (int i = 0; i < item.quantity; i++) {
        final bytes = <int>[];
        bytes.addAll(generator.reset());
        bytes.addAll(generator.feed(1));
        bytes.addAll(generator.text(
          item.name,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ));
        bytes.addAll(generator.feed(4));
        bytes.addAll(generator.cut(mode: PosCutMode.full));

        await _send(bytes);
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
  }

  Future<void> _send(List<int> bytes) async {
    final socket = await Socket.connect(
      ip,
      port,
      timeout: const Duration(seconds: 5),
    );
    socket.add(bytes);
    await socket.flush();
    await socket.close();
  }
}
