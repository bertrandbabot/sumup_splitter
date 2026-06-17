import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/local_order.dart';

class OrderCard extends StatelessWidget {
  final LocalOrder order;
  final String label;
  final Color tileColor;
  final VoidCallback onReprint;

  const OrderCard({
    super.key,
    required this.order,
    required this.label,
    required this.tileColor,
    required this.onReprint,
  });

  static Color colorForPrinterIndex(int index) {
    const colors = [
      Color.fromARGB(255, 118, 218, 121),
      Color.fromARGB(255, 118, 145, 218),
      Color.fromARGB(255, 218, 180, 118),
      Color.fromARGB(255, 218, 118, 180),
    ];
    return colors[index.clamp(0, colors.length - 1)];
  }

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
    final displayLabel =
        label.trim().isNotEmpty ? label.trim() : order.user.trim();

    return Card(
      child: ListTile(
        tileColor: tileColor,
        title: Row(
          children: [
            if (displayLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    displayLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            Expanded(
              child: Text(
                itemText.isEmpty
                    ? 'Commande ${order.transactionCode}'
                    : itemText,
              ),
            ),
          ],
        ),
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
