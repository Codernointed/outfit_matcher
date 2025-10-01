import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';

/// Keys for versioned storage (extracted for reuse)
class OutfitStorageKeys {
  const OutfitStorageKeys._();

  static const savedOutfits = 'saved_outfits_v1';
  static const wardrobeItems = 'wardrobe_items_v2';
  static const wardrobeLooks = 'wardrobe_looks_v2';
}

/// Lightweight persistence helper that stores generated outfits locally.
class OutfitStorageService {
  OutfitStorageService(this._preferences);

  static const _savedOutfitsKey = OutfitStorageKeys.savedOutfits;

  final SharedPreferences _preferences;

  Future<List<SavedOutfit>> fetchAll() async {
    final rawList = _preferences.getStringList(_savedOutfitsKey);
    if (rawList == null) return const [];

    return rawList
        .map((raw) {
          try {
            return SavedOutfit.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<SavedOutfit>()
        .toList(growable: false);
  }

  Future<SavedOutfit> save(SavedOutfit outfit) async {
    final allOutfits = await fetchAll();
    final updated = [outfit, ...allOutfits.where((o) => o.id != outfit.id)];
    await _preferences.setStringList(
      _savedOutfitsKey,
      updated.map((o) => o.toJsonString()).toList(growable: false),
    );
    return outfit;
  }

  Future<void> delete(String id) async {
    final allOutfits = await fetchAll();
    await _preferences.setStringList(
      _savedOutfitsKey,
      allOutfits
          .where((outfit) => outfit.id != id)
          .map((o) => o.toJsonString())
          .toList(growable: false),
    );
  }

  Future<void> clear() async {
    await _preferences.remove(_savedOutfitsKey);
  }
}
