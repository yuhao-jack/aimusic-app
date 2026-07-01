import 'package:flutter/material.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 全局网络状态 Banner — 在页面顶部显示网络断开/恢复提示
/// 网络断开时显示警告 Banner，网络恢复时显示成功 Banner 并自动消失
class NetworkBanner extends StatefulWidget {
  /// 是否有网络连接
  final bool isConnected;

  /// 网络恢复时的回调（用于触发自动重试）
  final VoidCallback? onNetworkRestored;

  NetworkBanner({
    super.key,
    required this.isConnected,
    this.onNetworkRestored,
  });

  @override
  State<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends State<NetworkBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _showBanner = false;
  bool _wasConnected = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 350),
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
  }

  @override
  void didUpdateWidget(NetworkBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 网络断开 → 显示断开 Banner
    if (!widget.isConnected && oldWidget.isConnected) {
      _wasConnected = false;
      setState(() => _showBanner = true);
      _controller.forward();
    }

    // 网络恢复 → 显示恢复 Banner，2秒后自动隐藏
    if (widget.isConnected && !_wasConnected) {
      _wasConnected = true;
      widget.onNetworkRestored?.call();
      // 短暂延迟后隐藏 Banner
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          _controller.reverse().then((_) {
            if (mounted) setState(() => _showBanner = false);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return SizedBox.shrink();

    final topPadding = MediaQuery.of(context).padding.top;
    final isDisconnected = !widget.isConnected;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.only(top: topPadding),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDisconnected
                  ? AppTheme.warningColor.withValues(alpha: 0.15)
                  : AppTheme.successColor.withValues(alpha: 0.15),
              border: Border(
                bottom: BorderSide(
                  color: isDisconnected
                      ? AppTheme.warningColor.withValues(alpha: 0.3)
                      : AppTheme.successColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDisconnected
                        ? AppTheme.warningColor.withValues(alpha: 0.2)
                        : AppTheme.successColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDisconnected
                        ? Icons.wifi_off_rounded
                        : Icons.wifi_rounded,
                    size: 16,
                    color: isDisconnected
                        ? AppTheme.warningColor
                        : AppTheme.successColor,
                  ),
                ),
                SizedBox(width: 12),
                // 文字
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDisconnected ? '网络已断开' : '网络已恢复',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDisconnected
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                        ),
                      ),
                      if (isDisconnected) ...[
                        SizedBox(height: 2),
                        Text(
                          '请检查网络连接，稍后自动重试',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSilver,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 加载指示器（断开时显示）
                if (isDisconnected)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.warningColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
