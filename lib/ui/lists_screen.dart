import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// Title screen: all shopping lists.
class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Text(
          l10n.noListsYet,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
