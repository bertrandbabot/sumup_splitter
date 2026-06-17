import 'sumup_receipt_item.dart';

class LocalOrder {
  final String id;
  final String transactionCode;
  final String receiptNo;
  final DateTime date;
  final String status;
  final String paymentType;
  final double amount;
  final String currency;
  final List<SumupReceiptItem> items;
  final String user;
  final int printerIndex;

  const LocalOrder({
    required this.id,
    required this.transactionCode,
    this.receiptNo = '',
    required this.date,
    required this.status,
    this.paymentType = '',
    required this.amount,
    required this.currency,
    required this.items,
    required this.user,
    this.printerIndex = 0,
  });

  bool get isPrinted => status == 'printed';
}
