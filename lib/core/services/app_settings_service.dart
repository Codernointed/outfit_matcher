import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service for managing app settings and preferences
class AppSettingsService {
  static const String _premiumPolishingKey = 'premium_polishing_enabled';
  static const String _autoSaveKey = 'auto_save_enabled';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _searchHistoryKey = 'home_search_history';
  static const String _favoriteOutfitIdsKey = 'favorite_outfit_ids';

  final SharedPreferences _prefs;

  AppSettingsService(this._prefs);

  /// Premium image polishing setting
  bool get isPremiumPolishingEnabled => _prefs.getBool(_premiumPolishingKey) ?? false;
  
  Future<void> setPremiumPolishing(bool enabled) async {
    await _prefs.setBool(_premiumPolishingKey, enabled);
    AppLogger.info('🎨 Premium polishing ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Auto-save setting
  bool get isAutoSaveEnabled => _prefs.getBool(_autoSaveKey) ?? true;
  
  Future<void> setAutoSave(bool enabled) async {
    await _prefs.setBool(_autoSaveKey, enabled);
    AppLogger.info('💾 Auto-save ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Notifications setting
  bool get areNotificationsEnabled => _prefs.getBool(_notificationsKey) ?? true;
  
  Future<void> setNotifications(bool enabled) async {
    await _prefs.setBool(_notificationsKey, enabled);
    AppLogger.info('🔔 Notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Preferred theme mode (dark / light)
  bool get isDarkModeEnabled => _prefs.getBool(_darkModeKey) ?? false;

  Future<void> setDarkModeEnabled(bool enabled) async {
    await _prefs.setBool(_darkModeKey, enabled);
    AppLogger.info('🌗 Theme mode set to ${enabled ? 'dark' : 'light'}');
  }

  /// Search history helpers
  List<String> getSearchHistory() {
    return _prefs.getStringList(_searchHistoryKey)?.toList(growable: false) ?? const [];
  }

  Future<void> addSearchTerm(String term, {int maxEntries = 6}) async {
    if (term.isEmpty) return;
    final history = getSearchHistory().toList(growable: true);
    history.removeWhere((element) => element.toLowerCase() == term.toLowerCase());
    history.insert(0, term);
    if (history.length > maxEntries) {
      history.removeRange(maxEntries, history.length);
    }
    await _prefs.setStringList(_searchHistoryKey, history);
    AppLogger.info('🔍 Search history updated', data: {'term': term});
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(_searchHistoryKey);
    AppLogger.info('🧹 Search history cleared');
  }

  /// Favorite outfits (stored as list of ids)
  List<String> getFavoriteOutfitIds() {
    return _prefs.getStringList(_favoriteOutfitIdsKey)?.toList(growable: false) ?? const [];
  }

  Future<void> setFavoriteOutfitIds(List<String> ids) async {
    await _prefs.setStringList(_favoriteOutfitIdsKey, ids);
    AppLogger.info('❤️ Favorite outfits updated', data: {'count': ids.length});
  }

  /// Get all settings as a map
  Map<String, dynamic> getAllSettings() {
    return {
      'premiumPolishing': isPremiumPolishingEnabled,
      'autoSave': isAutoSaveEnabled,
      'notifications': areNotificationsEnabled,
    };
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs.setBool(_premiumPolishingKey, false);
    await _prefs.setBool(_autoSaveKey, true);
    await _prefs.setBool(_notificationsKey, true);
    await _prefs.setBool(_darkModeKey, false);
    await _prefs.remove(_searchHistoryKey);
    await _prefs.remove(_favoriteOutfitIdsKey);
    AppLogger.info('🔄 Settings reset to defaults');
  }
}
