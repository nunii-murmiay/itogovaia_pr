import 'package:flutter/material.dart';
import '../models/category.dart';
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
    final categoryName = ProductCategory.getName(product.categoryId);

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
          : (isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2) : null),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onToggleSelect != null) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelect!(product.id),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.sku,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.isDeleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Удален',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: product.isDeleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${product.price.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _infoChip(Icons.category_outlined, categoryName, theme),
                _infoChip(Icons.business_outlined, supplierName, theme),
                _infoChip(Icons.inventory_2_outlined, '${product.stock} шт.', theme),
                _infoChip(Icons.star, '${product.rating}', theme, isStar: true),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (product.isDeleted && onRestore != null)
                  TextButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore_from_trash),
                    label: const Text('Восстановить'),
                  ),
                if (!product.isDeleted && onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Редактировать',
                    onPressed: onEdit,
                  ),
                if (!product.isDeleted && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Удалить',
                    color: theme.colorScheme.error,
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, ThemeData theme, {bool isStar = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isStar ? Colors.amber[800] : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
