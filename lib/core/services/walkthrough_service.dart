import 'package:shared_preferences/shared_preferences.dart';

/// Simple persistence layer for walkthrough flags.
class WalkthroughService {
  WalkthroughService(this._prefs);

  static const _homeKey = 'walkthrough_home_completed';
  static const _closetKey = 'walkthrough_closet_completed';

  final SharedPreferences _prefs;

  bool shouldShowHomeWalkthrough() => !(_prefs.getBool(_homeKey) ?? false);

  bool shouldShowClosetWalkthrough() => !(_prefs.getBool(_closetKey) ?? false);

  Future<void> completeHomeWalkthrough() => _prefs.setBool(_homeKey, true);

  Future<void> completeClosetWalkthrough() => _prefs.setBool(_closetKey, true);

  Future<void> resetAllWalkthroughs() async {
    await _prefs.remove(_homeKey);
    await _prefs.remove(_closetKey);
  }
}
