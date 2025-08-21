import 'package:shared_preferences/shared_preferences.dart';

class PermissionManager {
  static const String _permissionGrantedKey = 'permissions_granted';
  static const String _permissionAskedKey = 'permissions_asked';

  static Future<bool> arePermissionsGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionGrantedKey) ?? false;
  }

  static Future<void> setPermissionsGranted(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionGrantedKey, granted);
  }

  static Future<bool> hasAskedBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionAskedKey) ?? false;
  }

  static Future<void> setAskedBefore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionAskedKey, true);
  }
}
