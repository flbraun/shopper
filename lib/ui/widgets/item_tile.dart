import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';

/// One item of a list. Struck items are drawn struck through and dimmed.
class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item, required this.onTap});

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = item.struck
        ? theme.textTheme.bodyLarge?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: theme.colorScheme.outline,
          )
        : theme.textTheme.bodyLarge;
    return ListTile(
      title: Text(item.text, style: style),
      onTap: onTap,
    );
  }
}
