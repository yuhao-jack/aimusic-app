import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 统一的下拉刷新/上拉加载组件 - 丝滑的加载体验
class AppSmartRefresher extends StatelessWidget {
  final Widget child;
  final RefreshController controller;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoading;
  final bool enablePullUp;
  final bool enablePullDown;

  AppSmartRefresher({
    super.key,
    required this.child,
    required this.controller,
    this.onRefresh,
    this.onLoading,
    this.enablePullUp = false,
    this.enablePullDown = true,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: controller,
      enablePullDown: enablePullDown,
      enablePullUp: enablePullUp,
      onRefresh: onRefresh,
      onLoading: onLoading,
      header: _buildHeader(),
      footer: _buildFooter(),
      child: child,
    );
  }

  Widget _buildHeader() {
    return WaterDropHeader(
      waterDropColor: AppTheme.primaryColor,
      refresh: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
          strokeWidth: 2.5,
        ),
      ),
      idleIcon: Icon(
        Icons.arrow_downward_rounded,
        color: AppTheme.textSilver,
        size: 20,
      ),
    );
  }

  Widget _buildFooter() {
    return CustomFooter(
      builder: (context, mode) {
        Widget body;
        if (mode == LoadStatus.idle) {
          body = Text('');
        } else if (mode == LoadStatus.loading) {
          body = SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2.5,
            ),
          );
        } else if (mode == LoadStatus.failed) {
          body = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 16),
              SizedBox(width: 8),
              Text('加载失败，点击重试', style: TextStyle(color: AppTheme.textSilver, fontSize: 13)),
            ],
          );
        } else if (mode == LoadStatus.canLoading) {
          body = Text('加载更多', style: TextStyle(color: AppTheme.textSilver, fontSize: 13));
        } else {
          body = Text('— 没有更多了 —', style: TextStyle(color: AppTheme.textLightGray, fontSize: 13));
        }
        return Container(
          height: 55,
          alignment: Alignment.center,
          child: body,
        );
      },
    );
  }
}
