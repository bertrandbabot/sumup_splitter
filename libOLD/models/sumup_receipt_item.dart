class SumupReceiptItem {
  final String name;
  final int quantity;

  const SumupReceiptItem({
    required this.name,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
      };

  factory SumupReceiptItem.fromJson(Map<String, dynamic> json) {
    return SumupReceiptItem(
      name: json['name']?.toString() ?? 'Article',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    );
  }
}
