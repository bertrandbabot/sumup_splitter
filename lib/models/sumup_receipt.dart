import 'sumup_receipt_item.dart';

class SumupReceipt {
  final String transactionCode;
  final String transactionId;
  final String receiptNo;
  final DateTime timestamp;
  final String status;
  final String paymentType;
  final double amount;
  final String currency;
  final List<SumupReceiptItem> products;

  const SumupReceipt({
    required this.transactionCode,
    required this.transactionId,
    required this.receiptNo,
    required this.timestamp,
    required this.status,
    required this.paymentType,
    required this.amount,
    required this.currency,
    required this.products,
  });

  factory SumupReceipt.fromJson(Map<String, dynamic> json) {
    final tx = (json['transaction_data'] is Map<String, dynamic>)
        ? json['transaction_data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawProducts = tx['products'];
    final products = rawProducts is List
        ? rawProducts
            .whereType<Map<String, dynamic>>()
            .map(SumupReceiptItem.fromJson)
            .where((item) => item.name.trim().isNotEmpty && item.quantity > 0)
            .toList()
        : <SumupReceiptItem>[];

    return SumupReceipt(
      transactionCode: tx['transaction_code']?.toString() ?? '',
      transactionId: tx['transaction_id']?.toString() ?? '',
      receiptNo: tx['receipt_no']?.toString() ?? '',
      timestamp: DateTime.tryParse(tx['timestamp']?.toString() ?? '') ?? DateTime.now(),
      status: tx['status']?.toString() ?? '',
      paymentType: tx['payment_type']?.toString() ?? '',
      amount: double.tryParse(tx['amount']?.toString() ?? '0') ?? 0,
      currency: tx['currency']?.toString() ?? 'EUR',
      products: products,
    );
  }
}
