import 'package:flutter/material.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 骨架屏/闪烁加载组件 - 营造丝滑的加载体验
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppTheme.radiusMedium,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-_animation.value, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor ?? AppTheme.midDark,
                widget.highlightColor ?? AppTheme.darkCardElevated,
                widget.baseColor ?? AppTheme.midDark,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 推荐页面骨架屏
class RecommendTabShimmer extends StatelessWidget {
  const RecommendTabShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Quick actions shimmer
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Container(
                  height: 90,
                  margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                  decoration: BoxDecoration(
                    color: AppTheme.midDark,
                    borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Section title shimmer
          const ShimmerLoading(width: 120, height: 24),
          const SizedBox(height: 20),
          // Horizontal list shimmer
          SizedBox(
            height: 200,
            child: Row(
              children: List.generate(
                3,
                (i) => Container(
                  width: 160,
                  margin: EdgeInsets.only(right: i < 2 ? 16 : 0),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(width: 160, height: 140),
                      SizedBox(height: 12),
                      ShimmerLoading(width: 120, height: 16),
                      SizedBox(height: 8),
                      ShimmerLoading(width: 80, height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Another section title
          const ShimmerLoading(width: 100, height: 24),
          const SizedBox(height: 20),
          // Song list shimmer
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const ShimmerLoading(width: 56, height: 56, borderRadius: 8),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(width: double.infinity, height: 16),
                        SizedBox(height: 6),
                        ShimmerLoading(width: 100, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 页面加载骨架屏（通用）
class PageShimmer extends StatelessWidget {
  final int itemCount;
  final bool isList;
  final double itemHeight; // ignored, kept for API compatibility

  const PageShimmer({
    super.key,
    this.itemCount = 6,
    this.isList = true,
    this.itemHeight = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          itemCount,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: isList ? 16 : 20),
            child: isList
                ? _buildListShimmerItem()
                : _buildGridShimmerItem(),
          ),
        ),
      ),
    );
  }

  Widget _buildListShimmerItem() {
    return const Row(
      children: [
        ShimmerLoading(width: 56, height: 56, borderRadius: 8),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLoading(width: double.infinity, height: 16),
              SizedBox(height: 6),
              ShimmerLoading(width: 120, height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridShimmerItem() {
    return const ShimmerLoading(
      width: double.infinity,
      height: 120,
    );
  }
}
