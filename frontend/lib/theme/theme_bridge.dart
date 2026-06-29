import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/theme/theme_config.dart';
import 'package:aimusic_app/theme/theme_provider.dart';

/// 桥接类：将 ThemeConfig 转换为 Flutter ThemeData
///
/// 所有页面保持对 AppTheme 常量的引用不变，
/// 此桥接负责在 GetMaterialApp 层面生成正确的 ThemeData。
class ThemeBridge {
  /// 初始化 ThemeProvider（应在 runApp 前调用）
  static Future<void> init() async {
    Get.put(ThemeProvider(), permanent: true);
  }

  /// 获取当前主题配置
  static ThemeConfig get config => ThemeProvider.to.current;

  /// ========== 动态深色主题 ==========
  /// 注意：这是一个 getter（每次返回新实例），
  /// 因为在运行时主题会动态切换，不能缓存 const。
  static ThemeData get darkTheme {
    final c = config;
    final bool isLight = c.isLight;

    if (isLight) {
      // 即使选了浅色主题（月光白），深色模式仍然返回当前浅色配置
      return _buildLightThemeData(c);
    }

    return _buildDarkThemeData(c);
  }

  /// ========== 动态浅色主题 ==========
  static ThemeData get lightTheme {
    final c = config;
    return _buildLightThemeData(c);
  }

  /// 构建深色 ThemeData
  static ThemeData _buildDarkThemeData(ThemeConfig c) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: c.primary,
      scaffoldBackgroundColor: c.background,
      cardColor: c.surface,
      colorScheme: ColorScheme.dark(
        primary: c.primary,
        secondary: c.secondary,
        surface: c.surface,
        error: c.error,
      ),
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
          height: 1.2,
          letterSpacing: -0.5,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
          height: 1.25,
          letterSpacing: -0.3,
        ),
        displaySmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
          height: 1.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: c.textPrimary,
          height: 1.5,
          letterSpacing: 0.14,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: c.textSecondary,
          height: 1.5,
          letterSpacing: 0.14,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: c.textTertiary,
          height: 1.4,
          letterSpacing: 0.12,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: c.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: AppTheme.elevationNone,
        iconTheme: IconThemeData(color: c.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.background,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: AppTheme.elevationMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
          elevation: AppTheme.elevationNone,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.midDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: BorderSide(color: c.primary, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: AppTheme.elevationNone,
        color: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusMedium)),
        ),
      ),
    );
  }

  /// 构建浅色 ThemeData
  static ThemeData _buildLightThemeData(ThemeConfig c) {
    final textPrimary = c.textPrimary;
    final textSecondary = c.textSecondary;
    final textTertiary = c.textTertiary;
    final midDark = c.midDark;

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: c.primary,
      scaffoldBackgroundColor: c.background,
      cardColor: c.surface,
      colorScheme: ColorScheme.light(
        primary: c.primary,
        secondary: c.secondary,
        surface: c.surface,
        error: c.error,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.25,
          letterSpacing: -0.3,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
          letterSpacing: 0.14,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
          letterSpacing: 0.14,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textTertiary,
          height: 1.4,
          letterSpacing: 0.12,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: AppTheme.elevationNone,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: AppTheme.elevationMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
          elevation: AppTheme.elevationNone,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: midDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: BorderSide(color: c.primary, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: AppTheme.elevationNone,
        color: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusMedium)),
        ),
      ),
    );
  }
}
