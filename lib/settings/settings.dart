import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/item_sorting.dart';

/// App-wide settings, persisted in shared_preferences.
class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  static const itemOrderKey = 'item_order';
  static const struckPlacementKey = 'struck_placement';

  static const defaultItemOrder = ItemOrder.az;
  static const defaultStruckPlacement = StruckPlacement.moveToBottom;

  final SharedPreferencesWithCache _prefs;

  static Future<Settings> load() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {itemOrderKey, struckPlacementKey},
      ),
    );
    return Settings._(prefs);
  }

  ItemOrder get itemOrder =>
      _decode(ItemOrder.values, _prefs.getString(itemOrderKey)) ??
      defaultItemOrder;

  StruckPlacement get struckPlacement =>
      _decode(StruckPlacement.values, _prefs.getString(struckPlacementKey)) ??
      defaultStruckPlacement;

  Future<void> setItemOrder(ItemOrder value) async {
    await _prefs.setString(itemOrderKey, value.name);
    notifyListeners();
  }

  Future<void> setStruckPlacement(StruckPlacement value) async {
    await _prefs.setString(struckPlacementKey, value.name);
    notifyListeners();
  }

  /// Unknown or missing values fall back to the default.
  static T? _decode<T extends Enum>(List<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
