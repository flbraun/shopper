import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shopper/app.dart';
import 'package:shopper/data/list_repository.dart';
import 'package:shopper/settings/settings.dart';

import '../data/test_db.dart';

/// Starts the app on a fresh in-memory database and settings store.
/// [seed] can fill the database before the first frame.
Future<ListRepository> pumpApp(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Future<void> Function(ListRepository lists)? seed,
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();

  final (lists, settings) = await tester.runAsync(() async {
    final db = await openTestDatabase();
    addTearDown(db.close);
    final lists = ListRepository(db, clock: steppingClock());
    await seed?.call(lists);
    return (lists, await Settings.load());
  }) as (ListRepository, Settings);

  await tester.pumpWidget(ShopperApp(lists: lists, settings: settings));
  await settle(tester);
  return lists;
}

/// Lets pending database futures complete, then settles the UI.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// Names of the list cards, top to bottom.
List<String> listNames(WidgetTester tester) {
  final cards = find.byType(Card).evaluate().toList()
    ..sort((a, b) {
      final ya = (a.renderObject! as RenderBox).localToGlobal(Offset.zero).dy;
      final yb = (b.renderObject! as RenderBox).localToGlobal(Offset.zero).dy;
      return ya.compareTo(yb);
    });
  return [
    for (final card in cards)
      (find
                  .descendant(
                    of: find.byWidget(card.widget),
                    matching: find.byType(Text),
                  )
                  .evaluate()
                  .first
                  .widget
              as Text)
          .data!,
  ];
}
