import 'package:flutter/material.dart';

/// 音浪AI（MelodyAI）设计系统
/// 深色主题优先，科技感、分层质感、少即是多
class AppTheme {
  // ==================== BACKWARD COMPATIBILITY ====================
  // 保持原有常量，确保现有代码不会出错
  // NOTE: primaryColor and secondaryColor are redefined below in Backward compatibility aliases section (brandPurple=0xFF7C3AED, brandPink=0xFFEC4899)
  static const Color successColor = Color(0xFF10B981); // 成功色
  static const Color warningColor = Color(0xFFF59E0B); // 警告色
  static const Color errorColor = Color(0xFFEF4444); // 错误色

  static const Color lightBackgroundColor = Color(0xFFF9FAFB);
  static const Color darkBackgroundColor = Color(0xFF111827);

  static const Color lightCardColor = AppTheme.textWhite;
  static const Color darkCardColor = Color(0xFF1F2937);

  static const Color lightTextColor = Color(0xFF111827);
  static const Color darkTextColor = AppTheme.textWhite;

  // ==================== PRIMARY BRAND COLORS (深色基底 + 柔和蓝灰强调) ====================
  /// 品牌主色 — 柔和蓝灰（不刺眼，深色背景上清晰可读）
  static const Color brandIndigo = Color(0xFF8E99A4);
  /// 品牌副色 — 暖灰
  static const Color brandPurple = Color(0xFFB0A898);
  /// 品牌强调色 — 柔粉（点赞/收藏）
  static const Color brandPink = Color(0xFFC4A0A0);
  /// 品牌蓝 — 链接/信息色
  static const Color brandBlue = Color(0xFF7B9BB5);
  /// 品牌青 — 辅助色
  static const Color brandCyan = Color(0xFF6BA3A0);
  /// 中性白 — 文字/图标
  static const Color brandWhite = Color(0xFFFFFFFF);
  /// 中性浅灰 — 次要元素
  static const Color brandLightGray = Color(0xFFE5E5E5);
  /// 中性灰 — 辅助元素
  static const Color brandGray = Color(0xFFA1A1AA);
  /// 中性深色 — 文字/图标
  static const Color brandDark = Color(0xFF18181B);
  /// 中性深灰 — hover/active
  static const Color brandDarkActive = Color(0xFF27272A);
  /// 链接/交互色
  static const Color brandLink = Color(0xFF8585A3);

  // Backward compatibility aliases — primaryColor 为品牌主色
  static const Color primaryColor = brandIndigo;
  static const Color secondaryColor = brandPurple;
  static const Color musicPurple = brandIndigo;
  static const Color pinkAccent = brandPink;

  // ==================== ENHANCED SURFACE LAYERING ====================
  // 新的分层色板：从深到浅，用背景色分层替代边框
  static const Color nearBlack = Color(0xFF121212); // Deepest background (unchanged)
  static const Color darkSurface = Color(0xFF181818); // Base card (backward compat)
  static const Color midDark = Color(0xFF1F1F1F); // Interactive zones (backward compat)
  static const Color darkCardElevated = Color(0xFF252525); // Elevated card (backward compat)

  // === New layering system (from deepest to lightest) ===
  /// Layer 1: deepest background (app scaffold) — 纯黑
  static const Color surface1 = Color(0xFF000000);

  /// Layer 2: base card surface
  static const Color surface2 = Color(0xFF0A0A0A);

  /// Layer 3: elevated card / interactive area
  static const Color surface3 = Color(0xFF111111);

  /// Layer 4: floating / hover card
  static const Color surfaceElevated = Color(0xFF1A1A1A);

  // ==================== GLOW EFFECTS ====================
  /// Primary glow — 靛蓝微光
  static Color get glowPrimary => brandIndigo.withOpacity(0.08);

  /// Secondary glow — 紫色微光
  static Color get glowSecondary => brandPurple.withOpacity(0.05);

  /// Subtle white glow for deep dark areas
  static Color get glowSubtle => Colors.white.withOpacity(0.03);

  // ==================== GRADIENTS ====================
  /// 品牌渐变：柔和蓝灰 → 暖灰
  static const LinearGradient primaryToSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E99A4), Color(0xFFB0A898)],
  );

  /// 品牌渐变色列表
  static const List<Color> primaryGradientColors = [Color(0xFF8E99A4), Color(0xFFB0A898)];

  /// 极简深灰渐变（渐变背景）
  static const LinearGradient monoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
  );

  /// 柔和强调渐变
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1A8E99A4), Color(0x0D8E99A4)],
  );

  /// AI 渐变
  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1A8E99A4), Color(0x1AB0A898)],
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

  // ==================== TEXT COLORS ====================
  /// Primary text (pure white only)
  static const Color textWhite = Color(0xFFFFFFFF);

  /// Secondary text (single gray tone for readability) — GLASS: 提亮
  static const Color textSilver = Color(0xFFBFBFBF); // GLASS: 次要文字色

  /// Bright secondary
  static const Color textNearWhite = Color(0xFFCBCBCB);

  /// Inactive / muted
  static const Color textLightGray = Color(0xFF9CA3AF);

  /// Secondary body
  static const Color textDarkGray = Color(0xFF4B5563);

  /// Captions
  static const Color textMediumGray = Color(0xFF6B7280);

  /// Section titles, slightly muted
  static const Color textDeepGray = Color(0xFF8B8B8B);

  // ==================== BORDER & DIVIDER ====================
  /// Subtle border — 深灰极简边框
  static const Color borderSubtle = Color(0xFF222222);

  /// Standard border
  static const Color borderGray = Color(0xFF333333);

  /// Light border
  static const Color borderLight = Color(0xFF555555);

  /// Divider / separator
  static const Color separator = Color(0xFF2A2A2A);

  // ==================== LIGHT THEME COLORS ====================
  static const Color lightSurface = Color(0xFFF9FAFB);
  static const Color lightCard = AppTheme.textWhite;
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
    Color surface = surface2,
    double radius = radiusComfortable,
  }) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Elevated card decoration with subtle shadow
  static BoxDecoration elevatedCardDecoration({
    Color surface = surface3,
    double radius = radiusComfortable,
  }) {
    return BoxDecoration(
      color: surface,
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
    Color tint = surfaceElevated,
    double opacity = 0.75,
  }) {
    return BoxDecoration(
      color: tint.withOpacity(opacity),
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
        textTheme: const TextTheme(
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: elevationNone,
          iconTheme: IconThemeData(color: lightTextColor),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: lightTextColor,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
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
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            borderSide: const BorderSide(color: brandIndigo, width: 1),
          ),
        ),
        cardTheme: const CardThemeData(
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
        textTheme: const TextTheme(
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
            color: textDim, // GLASS: 使用 textDim 替代 textMediumGray
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: elevationNone,
          iconTheme: IconThemeData(color: textWhite),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textWhite,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
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
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            borderSide: const BorderSide(color: brandIndigo, width: 1),
          ),
        ),
        cardTheme: const CardThemeData(
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
    Color tint = surfaceElevated,
    double opacity = 0.7,
    double blurSigma = 12,
    bool addGlow = false,
  }) {
    return BoxDecoration(
      color: tint.withOpacity(opacity),
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
    Color glowColor = brandIndigo,
    Color bgColor = surface3,
    double glowWidth = 1.0,
  }) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glowColor.withOpacity(0.4),
        width: glowWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.15),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  /// GLASS: 紧凑间距 EdgeInsets
  static EdgeInsets get compactPadding => const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  /// GLASS: 带 BackdropFilter 的完整毛玻璃面板包装
  /// 使用: ClipRRect(child: BackdropFilter(filter: ...))
  static BoxDecoration fullGlassEffect({
    double radius = radiusXLarge,
    Color tint = surfaceElevated,
    double opacity = 0.75,
  }) {
    return BoxDecoration(
      color: tint.withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderSubtle.withOpacity(0.3),
        width: 0.5,
      ),
    );
  }
}
