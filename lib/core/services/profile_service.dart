import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service for managing user profile data and preferences
class ProfileService {
  final SharedPreferences _prefs;

  static const String _profileKey = 'user_profile_v1';
  static const String _themePreferenceKey = 'theme_preference';

  ProfileService(this._prefs);

  /// Get user profile data
  Future<ProfileData> getProfile() async {
    try {
      final jsonString = _prefs.getString(_profileKey);
      if (jsonString == null) {
        // First time user - create initial profile
        final initialProfile = ProfileData.initial();
        await updateProfile(initialProfile);
        AppLogger.info('📝 Created initial user profile');
        return initialProfile;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ProfileData.fromJson(json);
    } catch (e) {
      AppLogger.error('❌ Error loading profile', error: e);
      return ProfileData.initial();
    }
  }

  /// Update user profile data
  Future<void> updateProfile(ProfileData profile) async {
    try {
      final jsonString = jsonEncode(profile.toJson());
      await _prefs.setString(_profileKey, jsonString);
      AppLogger.info('✅ Profile updated: ${profile.userName}');
    } catch (e) {
      AppLogger.error('❌ Error saving profile', error: e);
    }
  }

  /// Update just the user name
  Future<void> updateUserName(String name) async {
    final profile = await getProfile();
    await updateProfile(profile.copyWith(userName: name));
  }

  /// Update just the user bio
  Future<void> updateUserBio(String? bio) async {
    final profile = await getProfile();
    await updateProfile(profile.copyWith(userBio: bio));
  }

  /// Update avatar path
  Future<void> updateAvatarPath(String? path) async {
    final profile = await getProfile();
    await updateProfile(profile.copyWith(avatarPath: path));
  }

  /// Update notifications setting
  Future<void> updateNotificationsEnabled(bool enabled) async {
    final profile = await getProfile();
    await updateProfile(profile.copyWith(notificationsEnabled: enabled));
  }

  /// Update gender preference
  Future<void> updateGenderPreference(Gender gender) async {
    final profile = await getProfile();
    await updateProfile(profile.copyWith(preferredGender: gender));
    AppLogger.info('👤 Gender preference updated: ${gender.displayName}');
  }

  /// Clear profile data (for sign out or reset)
  Future<void> clearProfile() async {
    try {
      await _prefs.remove(_profileKey);
      AppLogger.info('🗑️ Profile cleared');
    } catch (e) {
      AppLogger.error('❌ Error clearing profile', error: e);
    }
  }

  /// Save theme preference
  Future<void> saveThemePreference(ThemeMode mode) async {
    await _prefs.setString(_themePreferenceKey, mode.name);
    AppLogger.info('🎨 Theme preference saved: ${mode.name}');
  }

  /// Get theme preference
  ThemeMode getThemePreference() {
    final saved = _prefs.getString(_themePreferenceKey);
    if (saved == null) return ThemeMode.light;

    return ThemeMode.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ThemeMode.light,
    );
  }

  /// Link OAuth account (stub for future implementation)
  Future<void> linkOAuthAccount(String provider, String userId) async {
    final profile = await getProfile();
    await updateProfile(
      profile.copyWith(authProvider: provider, authUserId: userId),
    );
    AppLogger.info('🔗 OAuth account linked: $provider');
  }
}
