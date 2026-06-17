import 'package:flutter/material.dart';

import '../models/local_order.dart';
import '../models/printer_config.dart';
import 'order_card.dart';

class PrinterOrdersColumn extends StatelessWidget {
  final int printerIndex;
  final PrinterConfig printer;
  final List<LocalOrder> orders;
  final void Function(LocalOrder order) onReprint;

  const PrinterOrdersColumn({
    super.key,
    required this.printerIndex,
    required this.printer,
    required this.orders,
    required this.onReprint,
  });

  String get _headerTitle {
    if (printer.label.trim().isNotEmpty) {
      return printer.label.trim();
    }
    return 'Imprimante ${printerIndex + 1}';
  }

  String get _headerSubtitle {
    if (!printer.isConfigured) {
      return 'Non configurée';
    }
    if (printer.user.trim().isNotEmpty) {
      return printer.user.trim();
    }
    if (printerIndex == 0) {
      return 'Par défaut';
    }
    return printer.ip;
  }

  @override
  Widget build(BuildContext context) {
    final color = OrderCard.colorForPrinterIndex(printerIndex);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headerTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _headerSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${orders.length} commande(s)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        printer.isConfigured
                            ? 'Aucune commande'
                            : 'Imprimante non configurée',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OrderCard(
                          order: order,
                          label: printer.label,
                          tileColor: color.withValues(alpha: 0.35),
                          compact: true,
                          onReprint: () => onReprint(order),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
