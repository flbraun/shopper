import 'package:material_ui/material_ui.dart';

import '../../data/item_sorting.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';

/// A list on the title screen: name, preview of its unstruck items and the
/// struck/total status.
class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.overview,
    required this.itemOrder,
    this.onTap,
    this.elevation,
  });

  final ListOverview overview;
  final ItemOrder itemOrder;
  final VoidCallback? onTap;

  /// Raised while the card is being dragged.
  final double? elevation;

  static const previewMaxLines = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unstruck = sortItems(
      overview.items.where((item) => !item.struck),
      itemOrder,
      StruckPlacement.inPlace,
    );
    final preview = unstruck.map((item) => item.text).join(', ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: elevation,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(overview.list.name, style: theme.textTheme.titleMedium),
              if (preview.isNotEmpty)
                Text(
                  preview,
                  maxLines: previewMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              Text(
                AppLocalizations.of(context)
                    .listProgress(overview.struckCount, overview.items.length),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
