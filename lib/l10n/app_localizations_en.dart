// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shopper';

  @override
  String get noListsYet => 'No lists yet.';

  @override
  String get noItemsYet => 'No items yet.';

  @override
  String get newList => 'New list';

  @override
  String get listName => 'Name';

  @override
  String get listNameTaken => 'A list with this name already exists.';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String listProgress(int struck, int total) {
    return '$struck/$total';
  }

  @override
  String get deleteListDropTarget => 'Drop here to delete the list';

  @override
  String get removeStruckItems => 'Remove struck items';

  @override
  String get undo => 'Undo';

  @override
  String get addItemHint => 'Add item';

  @override
  String get duplicateItemTitle => 'Already on the list';

  @override
  String duplicateItemMessage(String item) {
    return '\"$item\" is already on this list. Add it a second time?';
  }

  @override
  String get addAnyway => 'Add anyway';

  @override
  String get settings => 'Settings';

  @override
  String get itemOrder => 'Item order';

  @override
  String get itemOrderAz => 'A–Z';

  @override
  String get itemOrderZa => 'Z–A';

  @override
  String get itemOrderAddedEarliest => 'Added earliest first';

  @override
  String get itemOrderAddedLatest => 'Added latest first';

  @override
  String get struckItems => 'Struck items';

  @override
  String get struckInPlace => 'Keep in place';

  @override
  String get struckMoveToBottom => 'Move to the bottom';
}
