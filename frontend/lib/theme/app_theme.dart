import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/theme_provider.dart';
import 'package:aimusic_app/theme/theme_config.dart';

/// 音浪AI（MelodyAI）设计系统
/// 深色主题优先，科技感、分层质感、少即是多
class AppTheme {
  // ==================== 动态主题色（跟随主题切换） ====================
  /// 获取当前主题配置
  static ThemeConfig get _currentTheme {
    try {
      return Get.find<ThemeProvider>().current;
    } catch (e) {
      return ThemeConfigs.musicPurple; // 默认主题
    }
  }

  /// 动态主色 — 跟随主题
  static Color get primary => _currentTheme.primary;

  /// 动态副色 — 跟随主题
  static Color get secondary => _currentTheme.secondary;

  /// 动态背景色 — 跟随主题
  static Color get background => _currentTheme.background;

  /// 动态卡片背景色 — 跟随主题
  static Color get surface => _currentTheme.surface;

  /// 动态文字主色 — 跟随主题
  static Color get textPrimary => _currentTheme.textPrimary;

  /// 动态文字次色 — 跟随主题
  static Color get textSecondary => _currentTheme.textSecondary;

  /// 动态文字第三级色 — 跟随主题
  static Color get textTertiary => _currentTheme.textTertiary;

  /// 动态强调色 — 跟随主题
  static Color get accent => _currentTheme.accent;

  /// 动态渐变起始色 — 跟随主题
  static Color get gradientStart => _currentTheme.gradientStart;

  /// 动态渐变结束色 — 跟随主题
  static Color get gradientEnd => _currentTheme.gradientEnd;

  /// 动态品牌渐变 — 跟随主题
  static LinearGradient get dynamicGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  // ==================== 动态表面色（跟随主题） ====================
  /// 动态最深层背景
  static Color get dynamicBackground => _currentTheme.background;

  /// 动态卡片背景
  static Color get dynamicSurface => _currentTheme.surface;

  /// 动态悬浮卡片背景
  static Color get dynamicSurfaceElevated => _currentTheme.surfaceElevated;

  /// 动态交互区域背景
  static Color get dynamicMidDark => _currentTheme.midDark;

  // ==================== 动态文字色（跟随主题） ====================
  /// 动态主要文字色
  static Color get dynamicTextPrimary => _currentTheme.textPrimary;

  /// 动态次要文字色
  static Color get dynamicTextSecondary => _currentTheme.textSecondary;

  /// 动态第三级文字色
  static Color get dynamicTextTertiary => _currentTheme.textTertiary;

  // ==================== BACKWARD COMPATIBILITY ====================
  // 保持原有常量，确保现有代码不会出错
  static const Color successColor = Color(0xFF10B981); // 成功色
  static const Color warningColor = Color(0xFFF59E0B); // 警告色
  static const Color errorColor = Color(0xFFEF4444); // 错误色

  static const Color lightBackgroundColor = Color(0xFFF9FAFB);
  static const Color darkBackgroundColor = Color(0xFF111827);

  static Color get lightCardColor => textWhite;
  static const Color darkCardColor = Color(0xFF1F2937);

  static const Color lightTextColor = Color(0xFF111827);
  static Color get darkTextColor => textWhite;

  // ==================== PRIMARY BRAND COLORS (动态，跟随主题) ====================
  /// 品牌主色
  static Color get brandIndigo => _currentTheme.primary;

  /// 品牌副色
  static Color get brandPurple => _currentTheme.secondary;

  /// 品牌强调色
  static Color get brandPink => _currentTheme.accent;

  /// 品牌蓝
  static Color get brandBlue => _currentTheme.primary;

  /// 品牌青
  static Color get brandCyan => _currentTheme.secondary;

  /// 中性白 — 文字/图标
  static const Color brandWhite = Color(0xFFFFFFFF);

  /// 中性浅灰 — 次要元素
  static Color get brandLightGray => _currentTheme.textSecondary;

  /// 中性灰 — 辅助元素
  static Color get brandGray => _currentTheme.textTertiary;

  /// 中性深色 — 文字/图标
  static Color get brandDark => _currentTheme.background;

  /// 中性深灰 — hover/active
  static Color get brandDarkActive => _currentTheme.surface;

  /// 链接/交互色
  static Color get brandLink => _currentTheme.primary;

  // Backward compatibility aliases — primaryColor 为品牌主色
  static Color get primaryColor => primary;
  static Color get secondaryColor => secondary;
  static Color get musicPurple => primary;
  static Color get pinkAccent => accent;

  // ==================== ENHANCED SURFACE LAYERING (动态，跟随主题) ====================
  /// 最深层背景
  static Color get nearBlack => _currentTheme.background;

  /// 卡片背景
  static Color get darkSurface => _currentTheme.surface;

  /// 交互区域
  static Color get midDark => _currentTheme.midDark;

  /// 悬浮卡片
  static Color get darkCardElevated => _currentTheme.surfaceElevated;

  // === New layering system (动态，跟随主题) ===
  /// Layer 1: deepest background (app scaffold)
  static Color get surface1 => _currentTheme.background;

  /// Layer 2: base card surface
  static Color get surface2 => _currentTheme.surface;

  /// Layer 3: elevated card / interactive area
  static Color get surface3 => _currentTheme.midDark;

  /// Layer 4: floating / hover card
  static Color get surfaceElevated => _currentTheme.surfaceElevated;

  // ==================== GLOW EFFECTS ====================
  /// Primary glow — 靛蓝微光
  static Color get glowPrimary => brandIndigo.withOpacity(0.08);

  /// Secondary glow — 紫色微光
  static Color get glowSecondary => brandPurple.withOpacity(0.05);

  /// Subtle white glow for deep dark areas
  static Color get glowSubtle => Colors.white.withOpacity(0.03);

  // ==================== GRADIENTS (动态，跟随主题) ====================
  /// 品牌渐变
  static LinearGradient get primaryToSecondary => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_currentTheme.gradientStart, _currentTheme.gradientEnd],
  );

  /// 品牌渐变色列表
  static List<Color> get primaryGradientColors => [_currentTheme.gradientStart, _currentTheme.gradientEnd];

  /// 极简深灰渐变（渐变背景）
  static LinearGradient get monoGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_currentTheme.surface, _currentTheme.background],
  );

  /// 柔和强调渐变
  static LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_currentTheme.primary.withOpacity(0.1), _currentTheme.primary.withOpacity(0.05)],
  );

  /// AI 渐变
  static LinearGradient get aiGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_currentTheme.primary.withOpacity(0.1), _currentTheme.secondary.withOpacity(0.1)],
  );

  /// 暖色渐变：柔粉系
  static const LinearGradient warmGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC4A0A0), Color(0xFFB08888)],
  );

  /// 冷色渐变：蓝灰
  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E99A4), Color(0xFF6BA3A0)],
  );

  /// 装饰渐变
  static const LinearGradient glassDecoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0A8E99A4), Color(0x058E99A4)],
  );

  /// 水晶科技渐变
  static const LinearGradient crystalTechGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E99A4), Color(0xFFB0A898)],
  );

  // ==================== TEXT COLORS (动态，跟随主题) ====================
  /// Primary text — 主要文字色
  static Color get textWhite => _currentTheme.textPrimary;

  /// Secondary text — 次要文字色
  static Color get textSilver => _currentTheme.textSecondary;

  /// Bright secondary
  static Color get textNearWhite => _currentTheme.textSecondary;

  /// Inactive / muted — 第三级文字色
  static Color get textLightGray => _currentTheme.textTertiary;

  /// Secondary body
  static Color get textDarkGray => _currentTheme.textTertiary;

  /// Captions
  static Color get textMediumGray => _currentTheme.textTertiary;

  /// Section titles, slightly muted
  static Color get textDeepGray => _currentTheme.textSecondary;

  // ==================== BORDER & DIVIDER (动态，跟随主题) ====================
  /// Subtle border — 深灰极简边框
  static Color get borderSubtle => _currentTheme.surfaceElevated;

  /// Standard border
  static Color get borderGray => _currentTheme.midDark;

  /// Light border
  static Color get borderLight => _currentTheme.midDark;

  /// Divider / separator
  static Color get separator => _currentTheme.surfaceElevated;

  // ==================== LIGHT THEME COLORS ====================
  static const Color lightSurface = Color(0xFFF9FAFB);
  static Color get lightCard => textWhite;
  static const Color lightText = Color(0xFF111827);

  // ==================== BORDER RADIUS CONSTANTS ====================
  static const double radiusXSmall = 4;
  static const double radiusSmall = 6;
  static const double radiusMedium = 8;
  static const double radiusComfortable = 12; // GLASS: 之前也是 12，保持不变（卡片圆角）
  static const double radiusLarge = 16; // GLASS: 从 16 保持不变（容器圆角）
  static const double radiusXLarge = 20; // GLASS: 从 20 保持不变（毛玻璃面板）
  static const double radiusExtraLarge = 24;
  static const double radiusPill = 500;
  static const double radiusFullPill = 9999;

  // ==================== SPACING CONSTANTS ====================
  static const double space2Xs = 2;
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2Xl = 24;
  static const double space3Xl = 32;
  static const double space4Xl = 40;
  static const double space5Xl = 48;

  // ==================== ELEVATION CONSTANTS ====================
  static const double elevationNone = 0;
  static const double elevationLow = 2;
  static const double elevationMedium = 8;
  static const double elevationHigh = 24;

  // ==================== PLAYER CONSTANTS ====================
  static const double miniPlayerHeight = 64;
  static const double circularPlayButtonSize = 56;
  static const double circularActionButtonSize = 44;

  // ==================== SHADOWS ====================
  static const BoxShadow shadowMedium = BoxShadow(
    color: Color(0x4D000000),
    blurRadius: 8,
    offset: Offset(0, 8),
  );

  static const BoxShadow shadowHeavy = BoxShadow(
    color: Color(0x80000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  /// Subtle glow shadow for cards
  static BoxShadow shadowGlow(Color color) {
    return BoxShadow(
      color: color.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    );
  }

  // ==================== UTILITY DECORATIONS ====================
  /// Subtle card decoration (no border, just layered background)
  static BoxDecoration cardDecoration({
    Color? surface,
    double radius = radiusComfortable,
  }) {
    return BoxDecoration(
      color: surface ?? surface2,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Elevated card decoration with subtle shadow
  static BoxDecoration elevatedCardDecoration({
    Color? surface,
    double radius = radiusComfortable,
  }) {
    return BoxDecoration(
      color: surface ?? surface3,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Glass-morphism style decoration — GLASS: 增强支持 BackdropFilter blur
  static BoxDecoration glassDecoration({
    double radius = radiusLarge,
    Color? tint,
    double opacity = 0.75,
  }) {
    return BoxDecoration(
      color: (tint ?? surfaceElevated).withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderSubtle.withOpacity(0.4),
        width: 0.5,
      ),
    );
  }

  // ==================== LIGHT THEME ====================
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: lightBackgroundColor,
        cardColor: lightCardColor,
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: lightTextColor,
            height: 1.2,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: lightTextColor,
            height: 1.25,
            letterSpacing: -0.3,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: lightTextColor,
            height: 1.3,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: lightTextColor,
            height: 1.4,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: lightTextColor,
            height: 1.5,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: lightTextColor,
            height: 1.5,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: lightTextColor,
            height: 1.5,
            letterSpacing: 0.14,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textDarkGray,
            height: 1.5,
            letterSpacing: 0.14,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textMediumGray,
            height: 1.4,
            letterSpacing: 0.12,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: lightTextColor,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: lightTextColor,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: elevationNone,
          iconTheme: IconThemeData(color: lightTextColor),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: lightTextColor,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: lightCardColor,
          selectedItemColor: brandIndigo,
          unselectedItemColor: textLightGray,
          type: BottomNavigationBarType.fixed,
          elevation: elevationMedium,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusFullPill),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
            elevation: elevationNone,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: midDark,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusComfortable),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusComfortable),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusComfortable),
            borderSide: BorderSide(color: brandIndigo, width: 1),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: elevationNone,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
          ),
        ),
      );

  // ==================== DARK THEME (Primary) ====================
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: surface1, // GLASS: 使用更深的 surface1 (0xFF0A0A0A)
        cardColor: surface3, // GLASS: 使用 surface3 (0xFF161618)
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textWhite,
            height: 1.2,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textWhite,
            height: 1.25,
            letterSpacing: -0.3,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textWhite,
            height: 1.3,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textWhite,
            height: 1.4,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textWhite,
            height: 1.5,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textWhite,
            height: 1.5,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textWhite,
            height: 1.5,
            letterSpacing: 0.14,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textSilver,
            height: 1.5,
            letterSpacing: 0.14,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textMediumGray, // GLASS: 使用 textDim 替代 textMediumGray
            height: 1.4,
            letterSpacing: 0.12,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkTextColor,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkTextColor,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: elevationNone,
          iconTheme: IconThemeData(color: textWhite),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textWhite,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surface1,
          selectedItemColor: brandIndigo,
          unselectedItemColor: textLightGray,
          type: BottomNavigationBarType.fixed,
          elevation: elevationMedium,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandIndigo,
            foregroundColor: textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusFullPill),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
            elevation: elevationNone,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface2, // GLASS: 使用 surface2 (0xFF0E0E12)
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusComfortable),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusComfortable),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusComfortable),
            borderSide: BorderSide(color: brandIndigo, width: 1),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: elevationNone,
          color: surface3, // GLASS: 使用 surface3
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
          ),
        ),
      );

  // ==================== CONVENIENCE METHODS ====================
  static BorderRadius get radiusSmallAll => BorderRadius.circular(radiusSmall);
  static BorderRadius get radiusMediumAll => BorderRadius.circular(radiusMedium);
  static BorderRadius get radiusComfortableAll => BorderRadius.circular(radiusComfortable);
  static BorderRadius get radiusLargeAll => BorderRadius.circular(radiusLarge);
  static BorderRadius get radiusXLargeAll => BorderRadius.circular(radiusXLarge);
  static BorderRadius get radiusExtraLargeAll => BorderRadius.circular(radiusExtraLarge);
  static BorderRadius get radiusPillAll => BorderRadius.circular(radiusPill);
  static BorderRadius get radiusFullPillAll => BorderRadius.circular(radiusFullPill);

  static RoundedRectangleBorder get pillButtonShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radiusFullPill),
  );

  static RoundedRectangleBorder get circularButtonShape => const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(1000)),
  );

  // ==================== MOOD RECOMMEND COLORS ====================
  /// 心情推荐颜色 — 用于首页心情推荐区域的时段标识
  static const Color moodMorning = Color(0xFFFFD700);     // 早安音乐 — 金色
  static const Color moodAfternoon = Color(0xFF90EE90);   // 午后放松 — 浅绿
  static const Color moodVitality = Color(0xFFFFA500);    // 下午活力 — 橙色
  static const Color moodDusk = Color(0xFFFF6347);        // 傍晚黄昏 — 番茄红
  static const Color moodNight = Color(0xFF4169E1);       // 夜晚陪伴 — 皇家蓝
  static const Color moodLateNight = Color(0xFF6A5ACD);   // 深夜电台 — 板岩紫

  // ==================== NEW GLASS DESIGN SYSTEM ====================
  // 以下为简约毛玻璃科技感设计系统新增内容

  // ==================== GLASS GLOW EFFECTS ====================
  /// GLASS: 主色辉光（靛蓝色，20% opacity）
  static Color get glowPrimaryAccent => brandIndigo.withOpacity(0.2);

  /// GLASS: 青色光效
  static Color get glowCyan => brandCyan.withOpacity(0.12);

  /// GLASS: 主色辉光（兼容旧名）
  static Color get glassGlowPrimary => glowPrimaryAccent;

  // ==================== SHIMMER GRADIENT ====================
  /// GLASS: 光泽渐变
  static const LinearGradient glassShimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8E99A4),
      Color(0xFFB0A898),
      Color(0xFF8E99A4),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ==================== TEXT COLORS (GLASS ADDITIONS) ====================
  /// GLASS: 辅助文字色 - 用于次要提示、占位符
  static const Color textDim = Color(0xFF52525B);

  // ==================== SPACING (GLASS ADDITIONS) ====================
  /// GLASS: 紧凑间距
  static const double spaceCompact = 6;

  // ==================== GLASS DECORATION METHODS ====================

  /// GLASS: 返回带毛玻璃效果的 BoxDecoration
  /// 使用 semi-transparent bg + border + 可选背景辉光
  /// 结合 BackdropFilter 使用时达到完整毛玻璃效果
  static BoxDecoration glassCard({
    double radius = radiusComfortable,
    Color? tint,
    double opacity = 0.7,
    double blurSigma = 12,
    bool addGlow = false,
  }) {
    return BoxDecoration(
      color: (tint ?? surfaceElevated).withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderSubtle.withOpacity(0.5),
        width: 0.5,
      ),
      boxShadow: addGlow
          ? [
              BoxShadow(
                color: brandIndigo.withOpacity(0.1),
                blurRadius: blurSigma,
                offset: const Offset(0, 0),
              ),
            ]
          : null,
    );
  }

  /// GLASS: 返回带辉光边框的 BoxDecoration
  /// 常用于强调卡片 / 选中状态
  static BoxDecoration glowBorder({
    double radius = radiusComfortable,
    Color? glowColor,
    Color? bgColor,
    double glowWidth = 1.0,
  }) {
    return BoxDecoration(
      color: bgColor ?? surface3,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (glowColor ?? brandIndigo).withOpacity(0.4),
        width: glowWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: (glowColor ?? brandIndigo).withOpacity(0.15),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  /// GLASS: 紧凑间距 EdgeInsets
  static EdgeInsets get compactPadding => EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  /// GLASS: 带 BackdropFilter 的完整毛玻璃面板包装
  /// 使用: ClipRRect(child: BackdropFilter(filter: ...))
  static BoxDecoration fullGlassEffect({
    double radius = radiusXLarge,
    Color? tint,
    double opacity = 0.75,
  }) {
    return BoxDecoration(
      color: (tint ?? surfaceElevated).withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderSubtle.withOpacity(0.3),
        width: 0.5,
      ),
    );
  }
}
