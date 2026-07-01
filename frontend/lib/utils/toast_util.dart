import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 统一的 Toast/通知工具类
/// 顶部弹出，现代风格，支持动画
class ToastUtil {
  static OverlayEntry? _currentToast;

  // ===== 兼容性别名 =====
  static void showSuccess(String message) => success(message);
  static void showError(String message) => error(message);
  static void showWarning(String message) => warning(message);
  static void showInfo(String message) => info(message);

  // ===== 成功提示 =====
  static void success(String message) {
    _show(
      message: message,
      icon: Icons.check_circle_rounded,
      color: AppTheme.successColor,
      bgColor: AppTheme.successColor.withOpacity(0.15),
      borderColor: AppTheme.successColor.withOpacity(0.3),
    );
  }

  // ===== 错误提示 =====
  static void error(String message) {
    _show(
      message: message,
      icon: Icons.error_rounded,
      color: AppTheme.errorColor,
      bgColor: AppTheme.errorColor.withOpacity(0.15),
      borderColor: AppTheme.errorColor.withOpacity(0.3),
      duration: Duration(seconds: 3),
    );
  }

  // ===== 警告提示 =====
  static void warning(String message) {
    _show(
      message: message,
      icon: Icons.warning_rounded,
      color: AppTheme.warningColor,
      bgColor: AppTheme.warningColor.withOpacity(0.15),
      borderColor: AppTheme.warningColor.withOpacity(0.3),
    );
  }

  // ===== 信息提示 =====
  static void info(String message) {
    _show(
      message: message,
      icon: Icons.info_rounded,
      color: AppTheme.brandBlue,
      bgColor: AppTheme.brandBlue.withOpacity(0.15),
      borderColor: AppTheme.brandBlue.withOpacity(0.3),
    );
  }

  // ===== 核心显示逻辑 =====
  static void _show({
    required String message,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 移除当前显示的toast
    _removeCurrent();

    final overlay = Get.overlayContext;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        icon: icon,
        color: color,
        bgColor: bgColor,
        borderColor: borderColor,
        onDismiss: () {
          entry.remove();
          _currentToast = null;
        },
      ),
    );

    _currentToast = entry;
    Overlay.of(overlay).insert(entry);

    // 自动移除
    Future.delayed(duration, () {
      if (_currentToast == entry) {
        entry.remove();
        _currentToast = null;
      }
    });
  }

  static void _removeCurrent() {
    _currentToast?.remove();
    _currentToast = null;
  }

  // ===== 加载中对话框 =====
  static void showLoading([String message = '加载中...']) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: AppTheme.borderSubtle.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppTheme.brandIndigo,
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSilver,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ===== 隐藏加载对话框 =====
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // ===== 确认对话框 =====
  static Future<bool?> showConfirm({
    required String title,
    required String message,
    String confirmText = '确定',
    String cancelText = '取消',
  }) {
    return Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: AppTheme.borderSubtle.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSilver,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSilver,
                        side: BorderSide(color: AppTheme.borderGray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(cancelText, style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: AppTheme.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(confirmText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toast 动画组件
class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onDismiss;

  _ToastWidget({
    required this.message,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (_) => _dismiss(),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface3,
                  borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                  border: Border.all(
                    color: widget.borderColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 18,
                        color: widget.color,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textWhite,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppTheme.textLightGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }
}
