// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Shopper';

  @override
  String get noListsYet => 'Noch keine Listen.';

  @override
  String get noItemsYet => 'Noch keine Einträge.';

  @override
  String get newList => 'Neue Liste';

  @override
  String get listName => 'Name';

  @override
  String get listNameTaken => 'Eine Liste mit diesem Namen existiert bereits.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get create => 'Erstellen';

  @override
  String listProgress(int struck, int total) {
    return '$struck/$total';
  }

  @override
  String get deleteListDropTarget => 'Hier ablegen, um die Liste zu löschen';

  @override
  String get removeStruckItems => 'Erledigte Einträge entfernen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get addItemHint => 'Eintrag hinzufügen';

  @override
  String get duplicateItemTitle => 'Bereits auf der Liste';

  @override
  String duplicateItemMessage(String item) {
    return '„$item“ ist bereits auf dieser Liste. Ein zweites Mal hinzufügen?';
  }

  @override
  String get addAnyway => 'Trotzdem hinzufügen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get itemOrder => 'Reihenfolge der Einträge';

  @override
  String get itemOrderAz => 'A–Z';

  @override
  String get itemOrderZa => 'Z–A';

  @override
  String get itemOrderAddedEarliest => 'Zuerst hinzugefügte zuerst';

  @override
  String get itemOrderAddedLatest => 'Zuletzt hinzugefügte zuerst';

  @override
  String get struckItems => 'Erledigte Einträge';

  @override
  String get struckInPlace => 'An ihrer Stelle lassen';

  @override
  String get struckMoveToBottom => 'Nach unten verschieben';
}
