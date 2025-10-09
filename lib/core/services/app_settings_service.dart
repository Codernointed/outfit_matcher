import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service for managing app settings and preferences
class AppSettingsService {
  static const String _premiumPolishingKey = 'premium_polishing_enabled';
  static const String _autoSaveKey = 'auto_save_enabled';
  static const String _notificationsKey = 'notifications_enabled';

  final SharedPreferences _prefs;

  AppSettingsService(this._prefs);

  /// Premium image polishing setting
  bool get isPremiumPolishingEnabled =>
      _prefs.getBool(_premiumPolishingKey) ?? false;

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
    AppLogger.info('🔄 Settings reset to defaults');
  }
}
