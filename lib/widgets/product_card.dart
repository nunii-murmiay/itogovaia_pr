import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String supplierName;
  final bool isSelected;
  final ValueChanged<int>? onToggleSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const ProductCard({
    super.key,
    required this.product,
    required this.supplierName,
    this.isSelected = false,
    this.onToggleSelect,
    this.onEdit,
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      color: product.isDeleted
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.15)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelect?.call(product.id),
                ),
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: product.isDeleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Text(
                  '${product.price.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Text('Артикул: ${product.sku} · $supplierName'),
            Text('Склад: ${product.stock} шт. · ★ ${product.rating}'),
            const SizedBox(height: 8),
            Row(
              children: [
                if (onEdit != null)
                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
                if (product.isDeleted)
                  IconButton(icon: const Icon(Icons.restore), onPressed: onRestore)
                else
                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
