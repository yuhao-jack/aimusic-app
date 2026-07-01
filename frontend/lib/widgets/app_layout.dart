import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 统一的布局组件库
class AppLayout {
  // ===== 板块标题 =====
  static Widget sectionTitle(
    String title, {
    String? actionText,
    VoidCallback? onActionTap,
    EdgeInsets? padding,
  }) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          if (actionText != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSilver,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                actionText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== 水平分隔线 =====
  static Widget divider({
    double height = 1,
    Color? color,
    double? indent,
    double? endIndent,
  }) {
    return Divider(
      height: height,
      thickness: height,
      color: color ?? AppTheme.borderGray.withOpacity(0.2),
      indent: indent,
      endIndent: endIndent,
    );
  }

  // ===== 垂直间距 =====
  static Widget verticalSpacing([double size = 16]) {
    return SizedBox(height: size);
  }

  // ===== 水平间距 =====
  static Widget horizontalSpacing([double size = 16]) {
    return SizedBox(width: size);
  }

  // ===== 页面安全区域 =====
  static Widget safeArea({
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }

  // ===== 页面容器 =====
  static Widget page({
    required Widget child,
    Color? backgroundColor,
    bool hasAppBar = true,
    bool resizeToAvoidBottomInset = true,
    PreferredSizeWidget? appBar,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppTheme.nearBlack,
      appBar: hasAppBar ? appBar : null,
      body: child,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  // ===== 滚动页面 =====
  static Widget scrollPage({
    required List<Widget> children,
    Color? backgroundColor,
    EdgeInsets? padding,
    bool hasAppBar = true,
    PreferredSizeWidget? appBar,
    Widget? floatingActionButton,
  }) {
    return page(
      backgroundColor: backgroundColor,
      hasAppBar: hasAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      child: SingleChildScrollView(
        padding: padding ?? EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  // ===== 加载状态 =====
  static Widget loading({
    String? message,
    double? size,
    Color? color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              color: color ?? AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppTheme.textSilver,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== 空状态 =====
  static Widget empty({
    required IconData icon,
    required String title,
    String? description,
    Widget? action,
    double? iconSize,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize ?? 64,
              color: AppTheme.textDarkGray.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSilver,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLightGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // ===== 错误状态 =====
  static Widget error({
    required String message,
    VoidCallback? onRetry,
    String retryText = '重试',
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorColor.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSilver,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded),
                label: Text(retryText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== AppBar =====
  static PreferredSizeWidget appBar({
    required String title,
    List<Widget>? actions,
    Color? backgroundColor,
    bool? centerTitle,
    bool implyLeading = true,
    VoidCallback? onBack,
    Widget? leading,
    double? elevation,
  }) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation ?? AppTheme.elevationNone,
      centerTitle: centerTitle,
      automaticallyImplyLeading: implyLeading,
      leading: leading ??
          (implyLeading
              ? IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textWhite),
                  onPressed: onBack ?? () => Get.back(),
                )
              : null),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textWhite,
        ),
      ),
      actions: actions,
    );
  }

  // ===== 透明 AppBar =====
  static PreferredSizeWidget transparentAppBar({
    required String title,
    List<Widget>? actions,
    bool centerTitle = true,
    VoidCallback? onBack,
    Widget? leading,
  }) {
    return appBar(
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: 0,
      onBack: onBack,
      leading: leading,
    );
  }
}
