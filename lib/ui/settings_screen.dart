import 'package:material_ui/material_ui.dart';

import '../data/item_sorting.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings.dart';

/// App-wide settings. Changes apply immediately.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          children: [
            _SectionHeader(l10n.itemOrder),
            RadioGroup<ItemOrder>(
              groupValue: settings.itemOrder,
              onChanged: (value) {
                if (value != null) settings.setItemOrder(value);
              },
              child: Column(
                children: [
                  for (final (value, label) in [
                    (ItemOrder.az, l10n.itemOrderAz),
                    (ItemOrder.za, l10n.itemOrderZa),
                    (ItemOrder.addedEarliest, l10n.itemOrderAddedEarliest),
                    (ItemOrder.addedLatest, l10n.itemOrderAddedLatest),
                  ])
                    RadioListTile<ItemOrder>(value: value, title: Text(label)),
                ],
              ),
            ),
            _SectionHeader(l10n.struckItems),
            RadioGroup<StruckPlacement>(
              groupValue: settings.struckPlacement,
              onChanged: (value) {
                if (value != null) settings.setStruckPlacement(value);
              },
              child: Column(
                children: [
                  for (final (value, label) in [
                    (StruckPlacement.inPlace, l10n.struckInPlace),
                    (StruckPlacement.moveToBottom, l10n.struckMoveToBottom),
                  ])
                    RadioListTile<StruckPlacement>(
                      value: value,
                      title: Text(label),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
