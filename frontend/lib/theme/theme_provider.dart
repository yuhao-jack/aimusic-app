import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aimusic_app/theme/theme_config.dart';

/// 主题模式枚举
enum ThemeModeOption {
  system, // 跟随系统
  dark,   // 始终深色
  light,  // 始终浅色
}

/// GetX 驱动的主题提供者
/// 负责管理当前主题索引、深浅色模式、持久化和全局切换
class ThemeProvider extends GetxController {
  static const String _themeIndexKey = 'savedThemeIndex';
  static const String _themeModeKey = 'savedThemeMode';

  /// 单例访问
  static ThemeProvider get to => Get.find<ThemeProvider>();

  /// 当前主题索引响应式状态
  final RxInt _currentIndex = 0.obs;

  /// 当前主题模式响应式状态
  final Rx<ThemeModeOption> _themeMode = ThemeModeOption.system.obs;

  /// 所有可用主题
  List<ThemeConfig> get themes => ThemeConfigs.all;

  /// 当前选中索引
  int get currentIndex => _currentIndex.value;

  /// 当前主题配置
  ThemeConfig get current => themes[_currentIndex.value];

  /// 当前主题索引（可监听）
  RxInt get currentIndexRx => _currentIndex;

  /// 当前主题模式
  ThemeModeOption get themeMode => _themeMode.value;

  /// 当前主题模式（可监听）
  Rx<ThemeModeOption> get themeModeRx => _themeMode;

  /// Flutter ThemeMode（用于 MaterialApp）
  ThemeMode get flutterThemeMode {
    switch (_themeMode.value) {
      case ThemeModeOption.system:
        return ThemeMode.system;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.light:
        return ThemeMode.light;
    }
  }

  /// 是否为深色模式（考虑系统设置）
  bool get isDarkMode {
    switch (_themeMode.value) {
      case ThemeModeOption.system:
        return current.isLight == false;
      case ThemeModeOption.dark:
        return true;
      case ThemeModeOption.light:
        return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadSaved();
  }

  /// 从 SharedPreferences 加载已保存的主题设置
  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载主题索引
      final savedIndex = prefs.getInt(_themeIndexKey) ?? 0;
      if (savedIndex >= 0 && savedIndex < themes.length) {
        _currentIndex.value = savedIndex;
      }

      // 加载主题模式
      final savedModeIndex = prefs.getInt(_themeModeKey) ?? 0;
      if (savedModeIndex >= 0 && savedModeIndex < ThemeModeOption.values.length) {
        _themeMode.value = ThemeModeOption.values[savedModeIndex];
      }
    } catch (e) {
      debugPrint('加载主题设置失败: $e');
      _currentIndex.value = 0;
      _themeMode.value = ThemeModeOption.system;
    }
  }

  /// 切换主题配色
  Future<void> selectTheme(int index) async {
    if (index < 0 || index >= themes.length) return;
    if (index == _currentIndex.value) return;

    _currentIndex.value = index;
    await _saveThemeIndex(index);
  }

  /// 切换主题模式（深色/浅色/跟随系统）
  Future<void> setThemeMode(ThemeModeOption mode) async {
    if (mode == _themeMode.value) return;

    _themeMode.value = mode;
    await _saveThemeMode(mode);

    // 通知 GetX 更新主题
    Get.forceAppUpdate();
  }

  /// 获取主题配置的便捷方法
  ThemeConfig getTheme(int index) => themes[index];

  /// 保存主题索引
  Future<void> _saveThemeIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeIndexKey, index);
    } catch (e) {
      debugPrint('保存主题索引失败: $e');
    }
  }

  /// 保存主题模式
  Future<void> _saveThemeMode(ThemeModeOption mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (e) {
      debugPrint('保存主题模式失败: $e');
    }
  }
}
