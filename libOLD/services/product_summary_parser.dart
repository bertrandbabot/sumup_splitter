import '../models/sumup_receipt_item.dart';

class ProductSummaryParser {
  static List<SumupReceiptItem> parse(String? summary) {
    if (summary == null || summary.trim().isEmpty) {
      return [];
    }

    final parts = summary
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final items = <SumupReceiptItem>[];
    final regex = RegExp(r'^(\d+)\s*x\s*(.+)$', caseSensitive: false);

    for (final part in parts) {
      final match = regex.firstMatch(part);

      if (match != null) {
        final quantity = int.tryParse(match.group(1) ?? '1') ?? 1;
        final name = match.group(2)?.trim() ?? part;
        items.add(SumupReceiptItem(name: name, quantity: quantity));
      } else {
        items.add(SumupReceiptItem(name: part, quantity: 1));
      }
    }

    return items;
  }
}
