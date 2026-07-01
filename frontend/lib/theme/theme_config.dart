import 'package:flutter/material.dart';

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

  ThemeConfig({
    required this.name,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    this.surfaceElevated = const Color(0xFF1A1A1A),
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
  static ThemeConfig musicPurple = ThemeConfig(
    name: '音浪紫',
    icon: '💜',
    primary: const Color(0xFFB0A898),
    secondary: const Color(0xFFC4A0A0),
    background: const Color(0xFF121212),
    surface: const Color(0xFF1A1A1A),
    surfaceElevated: const Color(0xFF242424),
    midDark: const Color(0xFF1F1F1F),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFB3B3B3),
    textTertiary: const Color(0xFF9CA3AF),
    accent: const Color(0xFFC4A0A0),
    error: const Color(0xFFEF4444),
    success: const Color(0xFF10B981),
    gradientStart: const Color(0xFFB0A898),
    gradientEnd: const Color(0xFFC4A0A0),
  );

  /// 2. 「极光蓝」🌊
  /// 深海蓝色调，更冷、更深邃
  static ThemeConfig auroraBlue = ThemeConfig(
    name: '极光蓝',
    icon: '🌊',
    primary: const Color(0xFF06B6D4),
    secondary: const Color(0xFF3B82F6),
    background: const Color(0xFF0A1628),
    surface: const Color(0xFF0F1F35),
    surfaceElevated: const Color(0xFF162944),
    midDark: const Color(0xFF1A2A40),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFB3B3B3),
    textTertiary: const Color(0xFF9CA3AF),
    accent: const Color(0xFF3B82F6),
    error: const Color(0xFFEF4444),
    success: const Color(0xFF10B981),
    gradientStart: const Color(0xFF06B6D4),
    gradientEnd: const Color(0xFF3B82F6),
  );

  /// 3. 「暮光绿」🌿
  /// 森林绿色调，自然宁静
  static ThemeConfig twilightGreen = ThemeConfig(
    name: '暮光绿',
    icon: '🌿',
    primary: const Color(0xFF10B981),
    secondary: const Color(0xFF34D399),
    background: const Color(0xFF0A1F15),
    surface: const Color(0xFF0F2A1C),
    surfaceElevated: const Color(0xFF163522),
    midDark: const Color(0xFF1A3526),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFB3B3B3),
    textTertiary: const Color(0xFF9CA3AF),
    accent: const Color(0xFF34D399),
    error: const Color(0xFFEF4444),
    success: const Color(0xFF10B981),
    gradientStart: const Color(0xFF10B981),
    gradientEnd: const Color(0xFF34D399),
  );

  /// 4. 「日落橙」🌅
  /// 暖橙色调，温暖活力
  static ThemeConfig sunsetOrange = ThemeConfig(
    name: '日落橙',
    icon: '🌅',
    primary: const Color(0xFFF59E0B),
    secondary: const Color(0xFFFB923C),
    background: const Color(0xFF1F140A),
    surface: const Color(0xFF2A1C0F),
    surfaceElevated: const Color(0xFF352515),
    midDark: const Color(0xFF35261A),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFB3B3B3),
    textTertiary: const Color(0xFF9CA3AF),
    accent: const Color(0xFFFB923C),
    error: const Color(0xFFEF4444),
    success: const Color(0xFF10B981),
    gradientStart: const Color(0xFFF59E0B),
    gradientEnd: const Color(0xFFFB923C),
  );

  /// 5. 「玫瑰红」🌹
  /// 玫瑰红色调，热情奔放
  static ThemeConfig roseRed = ThemeConfig(
    name: '玫瑰红',
    icon: '🌹',
    primary: const Color(0xFFE11D48),
    secondary: const Color(0xFFFB7185),
    background: const Color(0xFF1F0A12),
    surface: const Color(0xFF2A0F1A),
    surfaceElevated: const Color(0xFF351A25),
    midDark: const Color(0xFF351A25),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFB3B3B3),
    textTertiary: const Color(0xFF9CA3AF),
    accent: const Color(0xFFFB7185),
    error: const Color(0xFFEF4444),
    success: const Color(0xFF10B981),
    gradientStart: const Color(0xFFE11D48),
    gradientEnd: const Color(0xFFFB7185),
  );

  /// 6. 「月光白」🌙（浅色主题）
  static ThemeConfig moonlightWhite = ThemeConfig(
    name: '月光白',
    icon: '🌙',
    primary: const Color(0xFFB0A898),
    secondary: const Color(0xFFC4A0A0),
    background: const Color(0xFFF9FAFB),
    surface: const Color(0xFFFFFFFF),
    surfaceElevated: const Color(0xFFF9FAFB),
    midDark: const Color(0xFFF3F4F6),
    textPrimary: const Color(0xFF111827),
    textSecondary: const Color(0xFF6B7280),
    textTertiary: const Color(0xFF9CA3AF),
    accent: const Color(0xFFC4A0A0),
    error: const Color(0xFFEF4444),
    success: const Color(0xFF10B981),
    gradientStart: const Color(0xFFB0A898),
    gradientEnd: const Color(0xFFC4A0A0),
  );

  /// 所有主题列表（按顺序排列）
  static List<ThemeConfig> all = [
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
