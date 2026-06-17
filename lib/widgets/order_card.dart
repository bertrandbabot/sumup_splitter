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

    final receipt =
        order.receiptNo.isNotEmpty ? ' • Reçu ${order.receiptNo}' : '';
    final payment =
        order.paymentType.isNotEmpty ? ' • ${order.paymentType}' : '';

    return Card(
      child: ListTile(
        tileColor: order.user == "support@infonetik.fr"
            ? const Color.fromARGB(255, 118, 218, 121)
            : const Color.fromARGB(255, 118, 145, 218),
        title: Text(
            itemText.isEmpty ? 'Commande ${order.transactionCode}' : itemText),
        subtitle: Text(
          '$date • ${order.amount.toStringAsFixed(2)} ${order.currency}$payment$receipt\n${order.transactionCode}',
        ),
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
