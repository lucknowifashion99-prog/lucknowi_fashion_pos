import 'package:flutter/material.dart';

import '../../../../models/product.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onVariants;

  const ProductTile({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onVariants,
  });

  @override
  Widget build(BuildContext context) {
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
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.indigo.shade100,
          child: const Icon(
            Icons.inventory_2,
            color: Colors.indigo,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.department != null) ...[
              const SizedBox(height: 4),
              Text(
                product.department!,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 3),
            Text(
              'GST: ${product.gst}%',
            ),
            if (product.hsn != null &&
                product.hsn!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'HSN: ${product.hsn}',
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'variants') {
              onVariants();
            } else if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'variants',
              child: Row(
                children: [
                  Icon(Icons.style),
                  SizedBox(width: 10),
                  Text('Variants'),
                ],
              ),
            ),
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
          ],
        ),
      ),
    );
  }
}