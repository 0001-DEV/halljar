import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/store.dart';

class AuthService {
  static const String _userKey = 'halljar_user';
  static const String _storeKey = 'halljar_store';
  static const String _readConvsKey = 'halljar_vendor_read_timestamps';

  static User? currentUser;
  static Store? currentStore;

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    final storeStr = prefs.getString(_storeKey);

    if (userStr != null) {
      try {
        currentUser = User.fromJson(jsonDecode(userStr));
      } catch (_) {}
    }
    if (storeStr != null) {
      try {
        currentStore = Store.fromJson(jsonDecode(storeStr));
      } catch (_) {}
    }
  }

  static Future<void> saveSession({required User user, Store? store}) async {
    final prefs = await SharedPreferences.getInstance();
    currentUser = user;
    currentStore = store;
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    if (store != null) {
      await prefs.setString(_storeKey, jsonEncode(store.toJson()));
    } else {
      await prefs.remove(_storeKey);
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    currentUser = null;
    currentStore = null;
    await prefs.remove(_userKey);
    await prefs.remove(_storeKey);
  }

  static Future<Map<String, String>> getReadTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_readConvsKey);
    if (str != null) {
      try {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }
    return {};
  }

  static Future<void> markConversationRead(String convId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await getReadTimestamps();
    map[convId] = DateTime.now().toIso8601String();
    await prefs.setString(_readConvsKey, jsonEncode(map));
  }
}
