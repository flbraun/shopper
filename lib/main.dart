import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/database.dart';
import 'data/list_repository.dart';
import 'settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();
  final settings = await Settings.load();
  runApp(ShopperApp(lists: ListRepository(db), settings: settings));
}
