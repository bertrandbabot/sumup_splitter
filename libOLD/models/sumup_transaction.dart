class SumupTransaction {
  final String id;
  final String transactionCode;
  final DateTime timestamp;
  final String status;
  final String paymentType;
  final String type;
  final String? productSummary;
  final double amount;
  final String currency;

  const SumupTransaction({
    required this.id,
    required this.transactionCode,
    required this.timestamp,
    required this.status,
    required this.paymentType,
    required this.type,
    required this.productSummary,
    required this.amount,
    required this.currency,
  });

  String get uniqueKey => id.isNotEmpty ? id : transactionCode;

  bool get isPrintablePosPayment {
    return status.toUpperCase() == 'SUCCESSFUL' &&
        type.toUpperCase() == 'PAYMENT' &&
        /*paymentType.toUpperCase() == 'POS' &&*/
        (productSummary != null && productSummary!.trim().isNotEmpty);
  }

  factory SumupTransaction.fromJson(Map<String, dynamic> json) {
    return SumupTransaction(
      id: json['id']?.toString() ?? json['transaction_id']?.toString() ?? '',
      transactionCode: json['transaction_code']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? '',
      paymentType: json['payment_type']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      productSummary: json['product_summary']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'EUR',
    );
  }
}
