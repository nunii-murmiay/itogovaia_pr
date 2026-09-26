import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int page;
  final int size;
  final int totalPages;
  final int totalItems;
  final bool hasPrevious;
  final bool hasNext;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalItems,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Показывать по:',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: size,
                isDense: true,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(8),
                items: const [10, 25, 50].map((s) {
                  return DropdownMenuItem<int>(
                    value: s,
                    child: Text('$s шт.'),
                  );
                }).toList(),
                onChanged: (newSize) {
                  if (newSize != null) onSizeChanged(newSize);
                },
              ),
            ],
          ),
          Text(
            totalItems > 0
                ? 'Страница $page из $totalPages (всего $totalItems записей)'
                : 'Записи отсутствуют',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'На первую страницу',
                icon: const Icon(Icons.first_page),
                onPressed: hasPrevious ? () => onPageChanged(1) : null,
              ),
              IconButton(
                tooltip: 'Предыдущая страница',
                icon: const Icon(Icons.chevron_left),
                onPressed: hasPrevious ? () => onPageChanged(page - 1) : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Следующая страница',
                icon: const Icon(Icons.chevron_right),
                onPressed: hasNext ? () => onPageChanged(page + 1) : null,
              ),
              IconButton(
                tooltip: 'На последнюю страницу',
                icon: const Icon(Icons.last_page),
                onPressed: hasNext ? () => onPageChanged(totalPages) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
