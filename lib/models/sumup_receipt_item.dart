class SumupReceiptItem {
  final String name;
  final String description;
  final int quantity;
  final double price;
  final double totalPrice;

  const SumupReceiptItem({
    required this.name,
    this.description = '',
    required this.quantity,
    this.price = 0,
    this.totalPrice = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'quantity': quantity,
        'price': price,
        'totalPrice': totalPrice,
      };

  factory SumupReceiptItem.fromJson(Map<String, dynamic> json) {
    return SumupReceiptItem(
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Article',
      description: json['description']?.toString().trim() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      totalPrice: double.tryParse(
            json['totalPrice']?.toString() ??
                json['total_price']?.toString() ??
                json['total_with_vat']?.toString() ??
                '0',
          ) ??
          0,
    );
  }
}
