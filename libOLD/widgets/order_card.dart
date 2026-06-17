import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/local_order.dart';

class OrderCard extends StatelessWidget {
  final LocalOrder order;
  final VoidCallback onReprint;

  const OrderCard({
    super.key,
    required this.order,
    required this.onReprint,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM HH:mm:ss').format(order.date.toLocal());
    final itemText = order.items
        .map((e) => e.quantity > 1 ? '${e.quantity} x ${e.name}' : e.name)
        .join(', ');

    return Card(
      child: ListTile(
        title: Text(itemText.isEmpty ? 'Commande ${order.transactionCode}' : itemText),
        subtitle: Text('$date • ${order.amount.toStringAsFixed(2)} ${order.currency}\n${order.transactionCode}'),
        isThreeLine: true,
        trailing: ElevatedButton.icon(
          onPressed: onReprint,
          icon: const Icon(Icons.print),
          label: const Text('Réimprimer'),
        ),
      ),
    );
  }
}
