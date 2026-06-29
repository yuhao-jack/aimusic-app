import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageUtil {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 保存字符串
  static Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  // 获取字符串
  static String? getString(String key) {
    return _prefs.getString(key);
  }

  // 保存布尔值
  static Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  // 获取布尔值
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // 保存整数
  static Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  // 获取整数
  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // 保存JSON对象
  static Future<bool> setJson(String key, Map<String, dynamic> value) {
    return _prefs.setString(key, jsonEncode(value));
  }

  // 获取JSON对象
  static Map<String, dynamic>? getJson(String key) {
    String? str = _prefs.getString(key);
    if (str == null) return null;
    return jsonDecode(str);
  }

  // 删除指定key
  static Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  // 清空所有
  static Future<bool> clear() {
    return _prefs.clear();
  }
}
