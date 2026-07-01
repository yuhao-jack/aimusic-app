import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 页面过渡动画配置 - 让页面切换更丝滑
class PageTransition {
  /// 全景滑动（默认）
  static Transition slide = Transition.cupertino;

  /// 渐变过渡
  static Transition fade = Transition.fade;

  /// 缩放+渐变
  static Transition zoomFade = Transition.zoom;

  /// 从底部滑入（适合播放器、模态页）
  static Transition bottomSlide = Transition.downToUp;
}

/// 淡入动画组件 - 更干脆利落的入场
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration? delay;
  final Duration duration;
  final Curve curve;

  /// 是否从下方滑入（默认 true）
  final bool slideUp;

  /// 是否额外添加一个轻微的缩放效果
  final bool scaleIn;

  FadeInWidget({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.delay,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
    this.slideUp = true,
    this.scaleIn = false,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.slideUp) {
      _slide = Tween<Offset>(
        begin: Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    } else {
      _slide = Tween<Offset>(
        begin: Offset.zero,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    }

    if (widget.scaleIn) {
      _scale = Tween<double>(begin: 0.97, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
    } else {
      _scale = Tween<double>(begin: 1.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
    }

    final effectiveMs = widget.delay?.inMilliseconds ?? widget.delayMs;
    Future.delayed(Duration(milliseconds: effectiveMs > 0 ? effectiveMs : 0), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _slide.value,
            child: Transform.scale(
              scale: _scale.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// 交错动画列表包装器
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final int startDelay;
  final int staggerDelay;

  StaggeredList({
    super.key,
    required this.children,
    this.padding,
    this.startDelay = 0,
    this.staggerDelay = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        children: List.generate(children.length, (index) {
          return FadeInWidget(
            delayMs: startDelay + index * staggerDelay,
            child: children[index],
          );
        }),
      ),
    );
  }
}

/// 弹性缩放按钮 - 按压时轻微回弹
class ElasticButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleAmount;
  final Color? splashColor;

  ElasticButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleAmount = 0.97,
    this.splashColor,
  });

  @override
  State<ElasticButton> createState() => _ElasticButtonState();
}

class _ElasticButtonState extends State<ElasticButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleAmount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    // 触觉反馈 - 轻量级点击振动
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// 玻璃卡片容器组件 - 毛玻璃效果
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurIntensity;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 16,
    this.blurIntensity = 10,
    this.margin,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
        child: Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: AppTheme.surface3.withOpacity(0.6),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppTheme.borderSubtle.withOpacity(0.4),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return ElasticButton(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

/// 扩展型FAB - 更简洁
class ExtendedFAB extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  ExtendedFAB({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElasticButton(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.brandIndigo, AppTheme.brandPurple],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandIndigo.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textWhite, size: 18),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 淡入+缩放的面板组件
class ScaleFadeIn extends StatefulWidget {
  final Widget child;
  final double beginScale;
  final Duration duration;
  final int delayMs;

  ScaleFadeIn({
    super.key,
    required this.child,
    this.beginScale = 0.95,
    this.duration = const Duration(milliseconds: 300),
    this.delayMs = 0,
  });

  @override
  State<ScaleFadeIn> createState() => _ScaleFadeInState();
}

class _ScaleFadeInState extends State<ScaleFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: widget.beginScale, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: (_animation.value - widget.beginScale) / (1.0 - widget.beginScale),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// 点赞心形按钮 - 带弹跳缩放动画
/// 点击时播放缩放动画（从小到大再缩回），已点赞时填充红色心形
class LikeButton extends StatefulWidget {
  /// 当前是否已点赞
  final bool isLiked;

  /// 点击回调
  final VoidCallback? onTap;

  /// 图标大小
  final double size;

  /// 已点赞颜色
  final Color? activeColor;

  /// 未点赞颜色
  final Color? inactiveColor;

  LikeButton({
    super.key,
    required this.isLiked,
    this.onTap,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    // 弹性曲线：从小到大再弹回
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    // 初始状态为正常大小
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // 重置并播放弹跳动画
    _controller.forward(from: 0.0);
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(6),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Icon(
            widget.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: widget.size,
            color: widget.isLiked ? (widget.activeColor ?? AppTheme.brandPink) : (widget.inactiveColor ?? AppTheme.textLightGray),
          ),
        ),
      ),
    );
  }
}
