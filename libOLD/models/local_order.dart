import 'sumup_receipt_item.dart';

class LocalOrder {
  final String id;
  final String transactionCode;
  final DateTime date;
  final String status;
  final double amount;
  final String currency;
  final String productSummary;
  final List<SumupReceiptItem> items;

  const LocalOrder({
    required this.id,
    required this.transactionCode,
    required this.date,
    required this.status,
    required this.amount,
    required this.currency,
    required this.productSummary,
    required this.items,
  });

  bool get isPrinted => status == 'printed';
}
