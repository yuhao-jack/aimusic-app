import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 单个主题配置定义
/// 包含完整的色板，与 AppTheme 现有常量对应
class ThemeConfig {
  final String name; // 显示名称
  final String icon; // emoji 图标
  final Color primary; // 主色
  final Color secondary; // 辅助色
  final Color background; // 最深层背景 (≈ nearBlack)
  final Color surface; // 卡片背景 (≈ darkSurface)
  final Color surfaceElevated; // 悬浮卡片
  final Color midDark; // 交互区域 (≈ midDark)
  final Color textPrimary; // 主要文字 (≈ textWhite)
  final Color textSecondary; // 次要文字 (≈ textSilver)
  final Color textTertiary; // 第三级文字 (≈ textLightGray)
  final Color accent; // 强调色
  final Color error; // 错误色
  final Color success; // 成功色
  final Color gradientStart; // 渐变起始
  final Color gradientEnd; // 渐变结束

  const ThemeConfig({
    required this.name,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    this.surfaceElevated = AppTheme.surfaceElevated,
    this.midDark = const Color(0xFF1F1F1F),
    this.textPrimary = const Color(0xFFFFFFFF),
    this.textSecondary = const Color(0xFFB3B3B3),
    this.textTertiary = const Color(0xFF9CA3AF),
    this.accent = const Color(0xFFEC4899),
    this.error = const Color(0xFFEF4444),
    this.success = const Color(0xFF10B981),
    required this.gradientStart,
    required this.gradientEnd,
  });

  /// 是否为浅色主题（根据背景色亮度判断）
  bool get isLight {
    return background.computeLuminance() > 0.5;
  }

  /// 获取 BackgroundColor 别名（兼容 AppTheme.nearBlack）
  Color get nearBlack => background;

  /// darkSurface 别名
  Color get darkSurface => surface;
}

/// ====================================================================
/// 预定义的 6 套主题 — 每个主题有更独特的表面层次
/// ====================================================================

class ThemeConfigs {
  /// 1. 「音浪紫」💜（默认当前主题）
  /// 主打紫色科技感，深色背景
  static const ThemeConfig musicPurple = ThemeConfig(
    name: '音浪紫',
    icon: '💜',
    primary: AppTheme.brandPurple,
    secondary: AppTheme.brandPink,
    background: Color(0xFF121212),
    surface: Color(0xFF1A1A1A),
    surfaceElevated: Color(0xFF242424),
    midDark: Color(0xFF1F1F1F),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textTertiary: Color(0xFF9CA3AF),
    accent: AppTheme.brandPink,
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    gradientStart: AppTheme.brandPurple,
    gradientEnd: AppTheme.brandPink,
  );

  /// 2. 「极光蓝」🌊
  /// 深海蓝色调，更冷、更深邃
  static const ThemeConfig auroraBlue = ThemeConfig(
    name: '极光蓝',
    icon: '🌊',
    primary: Color(0xFF06B6D4),
    secondary: Color(0xFF3B82F6),
    background: Color(0xFF0A1628),
    surface: Color(0xFF0F1F35),
    surfaceElevated: Color(0xFF162944),
    midDark: Color(0xFF1A2A40),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textTertiary: Color(0xFF9CA3AF),
    accent: Color(0xFF3B82F6),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    gradientStart: Color(0xFF06B6D4),
    gradientEnd: Color(0xFF3B82F6),
  );

  /// 3. 「暮光绿」🌿
  /// 森林绿色调，自然宁静
  static const ThemeConfig twilightGreen = ThemeConfig(
    name: '暮光绿',
    icon: '🌿',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF34D399),
    background: Color(0xFF0A1F15),
    surface: Color(0xFF0F2A1C),
    surfaceElevated: Color(0xFF163522),
    midDark: Color(0xFF1A3526),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textTertiary: Color(0xFF9CA3AF),
    accent: Color(0xFF34D399),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    gradientStart: Color(0xFF10B981),
    gradientEnd: Color(0xFF34D399),
  );

  /// 4. 「日落橙」🌅
  /// 暖橙色调，温暖活力
  static const ThemeConfig sunsetOrange = ThemeConfig(
    name: '日落橙',
    icon: '🌅',
    primary: Color(0xFFF59E0B),
    secondary: Color(0xFFFB923C),
    background: Color(0xFF1F140A),
    surface: Color(0xFF2A1C0F),
    surfaceElevated: Color(0xFF352515),
    midDark: Color(0xFF35261A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textTertiary: Color(0xFF9CA3AF),
    accent: Color(0xFFFB923C),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    gradientStart: Color(0xFFF59E0B),
    gradientEnd: Color(0xFFFB923C),
  );

  /// 5. 「玫瑰红」🌹
  /// 玫瑰红色调，热情奔放
  static const ThemeConfig roseRed = ThemeConfig(
    name: '玫瑰红',
    icon: '🌹',
    primary: Color(0xFFE11D48),
    secondary: Color(0xFFFB7185),
    background: Color(0xFF1F0A12),
    surface: Color(0xFF2A0F1A),
    surfaceElevated: Color(0xFF351A25),
    midDark: Color(0xFF351A25),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textTertiary: Color(0xFF9CA3AF),
    accent: Color(0xFFFB7185),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    gradientStart: Color(0xFFE11D48),
    gradientEnd: Color(0xFFFB7185),
  );

  /// 6. 「月光白」🌙（浅色主题）
  static const ThemeConfig moonlightWhite = ThemeConfig(
    name: '月光白',
    icon: '🌙',
    primary: AppTheme.brandPurple,
    secondary: AppTheme.brandPink,
    background: Color(0xFFF9FAFB),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF9FAFB),
    midDark: Color(0xFFF3F4F6),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    accent: AppTheme.brandPink,
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    gradientStart: AppTheme.brandPurple,
    gradientEnd: AppTheme.brandPink,
  );

  /// 所有主题列表（按顺序排列）
  static const List<ThemeConfig> all = [
    musicPurple,
    auroraBlue,
    twilightGreen,
    sunsetOrange,
    roseRed,
    moonlightWhite,
  ];

  /// 根据索引获取主题配置
  static ThemeConfig getByIndex(int index) => all[index];
}
