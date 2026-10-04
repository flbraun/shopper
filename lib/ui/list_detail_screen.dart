import 'package:material_ui/material_ui.dart';

import '../data/list_repository.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings.dart';

/// Items of one list.
// Placeholder until milestone 4 (items, strike, broom, add field).
class ListDetailScreen extends StatelessWidget {
  const ListDetailScreen({
    super.key,
    required this.list,
    required this.lists,
    required this.settings,
  });

  final ShoppingList list;
  final ListRepository lists;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(list.name)),
      body: Center(child: Text(AppLocalizations.of(context).noItemsYet)),
    );
  }
}
