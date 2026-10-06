import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // User Name
  Future<bool> setUserName(String name) async {
    return await _prefs.setString(AppConstants.prefsKeyUserName, name);
  }

  String? getUserName() {
    return _prefs.getString(AppConstants.prefsKeyUserName);
  }

  // User ID
  Future<bool> setUserId(String id) async {
    return await _prefs.setString(AppConstants.prefsKeyUserId, id);
  }

  String? getUserId() {
    return _prefs.getString(AppConstants.prefsKeyUserId);
  }

  // Onboarding status
  Future<bool> setIsOnboarded(bool value) async {
    return await _prefs.setBool(AppConstants.prefsKeyIsOnboarded, value);
  }

  bool isOnboarded() {
    return _prefs.getBool(AppConstants.prefsKeyIsOnboarded) ?? false;
  }

  // Clear (e.g. for testing / reset)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
