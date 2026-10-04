import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shopper/data/item_sorting.dart';
import 'package:shopper/settings/settings.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('defaults: A-Z, struck items move to the bottom', () async {
    final settings = await Settings.load();
    expect(settings.itemOrder, ItemOrder.az);
    expect(settings.struckPlacement, StruckPlacement.moveToBottom);
  });

  test('changes are persisted and notify listeners', () async {
    final settings = await Settings.load();
    var notified = 0;
    settings.addListener(() => notified++);

    await settings.setItemOrder(ItemOrder.addedLatest);
    await settings.setStruckPlacement(StruckPlacement.inPlace);
    expect(notified, 2);

    final reloaded = await Settings.load();
    expect(reloaded.itemOrder, ItemOrder.addedLatest);
    expect(reloaded.struckPlacement, StruckPlacement.inPlace);
  });

  test('unknown stored values fall back to the defaults', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          Settings.itemOrderKey: 'bogus',
          Settings.struckPlacementKey: 'bogus',
        });
    final settings = await Settings.load();
    expect(settings.itemOrder, ItemOrder.az);
    expect(settings.struckPlacement, StruckPlacement.moveToBottom);
  });
}
