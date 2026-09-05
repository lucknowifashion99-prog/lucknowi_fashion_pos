import 'package:flutter/material.dart';

import '../../../../models/product_variant.dart';

class VariantTile extends StatelessWidget {
  final VoidCallback onPrint;
  final ProductVariant variant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VariantTile({
    super.key,
    required this.variant,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final stockLow = variant.stock <= 5;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: stockLow
              ? Colors.orange.shade100
              : Colors.indigo.shade100,
          child: Icon(
            Icons.inventory_2,
            color: stockLow
                ? Colors.orange
                : Colors.indigo,
          ),
        ),
        title: Text(
          '${variant.color} / ${variant.size}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),

            Text(
              'SKU: ${variant.sku}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              'Barcode: ${variant.barcode}',
            ),

            const SizedBox(height: 3),

            Text(
              'Purchase: ₹${variant.purchasePrice.toStringAsFixed(2)}'
                  '   •   Selling: ₹${variant.sellingPrice.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 3),

            Row(
              children: [
                const Text(
                  'Stock: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${variant.stock}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: stockLow
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
                if (stockLow) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Low Stock',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            } else if (value == 'print') {
              onPrint();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 10),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print),
                  SizedBox(width: 10),
                  Text('Print Barcode'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}