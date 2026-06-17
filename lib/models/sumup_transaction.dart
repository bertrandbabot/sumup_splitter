class SumupTransaction {
  final String id;
  final String transactionCode;
  final DateTime timestamp;
  final String status;
  final String paymentType;
  final String type;
  final double amount;
  final String currency;
  final String user;

  const SumupTransaction({
    required this.id,
    required this.transactionCode,
    required this.timestamp,
    required this.status,
    required this.paymentType,
    required this.type,
    required this.amount,
    required this.currency,
    required this.user,
  });

  String get uniqueKey => id.isNotEmpty ? id : transactionCode;

  bool get isSuccessfulPayment {
    return status.toUpperCase() == 'SUCCESSFUL' &&
        type.toUpperCase() == 'PAYMENT' &&
        transactionCode.trim().isNotEmpty;
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
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'EUR',
      user: json['user']?.toString() ?? '',
    );
  }
}
