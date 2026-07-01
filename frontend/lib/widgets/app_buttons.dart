import 'package:flutter/material.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 统一的按钮组件库
class AppButtons {
  // ===== 主按钮 =====
  static Widget primary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    double? height = 56,
    double? width,
    bool enabled = true,
  }) {
    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandIndigo,
          foregroundColor: AppTheme.textWhite,
          disabledBackgroundColor: AppTheme.brandIndigo.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
          elevation: AppTheme.elevationNone,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.textWhite,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
      ),
    );
  }

  // ===== 次要按钮 =====
  static Widget secondary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    double? height = 56,
    double? width,
    bool enabled = true,
  }) {
    return SizedBox(
      height: height,
      width: width,
      child: OutlinedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.brandIndigo,
          side: BorderSide(color: AppTheme.brandIndigo),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // ===== 文本按钮 =====
  static Widget text({
    required String text,
    required VoidCallback? onPressed,
    Color? color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppTheme.brandIndigo,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  // ===== 图标按钮 =====
  static Widget icon({
    required IconData icon,
    required VoidCallback? onPressed,
    double size = 44,
    Color? color,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            )
          : null,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: iconColor ?? AppTheme.textWhite,
          size: size * 0.55,
        ),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tight(Size(size, size)),
      ),
    );
  }

  // ===== 小按钮（用于卡片等场景 =====
  static Widget small({
    required String text,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppTheme.brandIndigo,
          side: BorderSide(color: backgroundColor ?? AppTheme.brandIndigo),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.brandIndigo,
        foregroundColor: textColor ?? AppTheme.textWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
        ),
        elevation: AppTheme.elevationNone,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
