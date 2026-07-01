import 'package:flutter/material.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 骨架屏/闪烁加载组件 - 营造丝滑的加载体验
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  ShimmerLoading({
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
      duration: Duration(milliseconds: 1500),
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
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 推荐页面骨架屏
class RecommendTabShimmer extends StatelessWidget {
  RecommendTabShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
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
          SizedBox(height: 40),
          // Section title shimmer
          ShimmerLoading(width: 120, height: 24),
          SizedBox(height: 20),
          // Horizontal list shimmer
          SizedBox(
            height: 200,
            child: Row(
              children: List.generate(
                3,
                (i) => Container(
                  width: 160,
                  margin: EdgeInsets.only(right: i < 2 ? 16 : 0),
                  child: Column(
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
          SizedBox(height: 40),
          // Another section title
          ShimmerLoading(width: 100, height: 24),
          SizedBox(height: 20),
          // Song list shimmer
          ...List.generate(
            5,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ShimmerLoading(width: 56, height: 56, borderRadius: 8),
                  SizedBox(width: 12),
                  Expanded(
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

  PageShimmer({
    super.key,
    this.itemCount = 6,
    this.isList = true,
    this.itemHeight = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
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
    return Row(
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
    return ShimmerLoading(
      width: double.infinity,
      height: 120,
    );
  }
}

/// 歌曲卡片骨架屏 — 用于歌曲列表加载
class SongCardShimmer extends StatelessWidget {
  SongCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          // 封面占位
          ShimmerLoading(
            width: 56,
            height: 56,
            borderRadius: AppTheme.radiusMedium,
          ),
          SizedBox(width: 12),
          // 歌曲信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 歌名
                ShimmerLoading(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 16,
                  borderRadius: AppTheme.radiusSmall,
                ),
                SizedBox(height: 8),
                // 歌手名
                ShimmerLoading(
                  width: 100,
                  height: 12,
                  borderRadius: AppTheme.radiusSmall,
                ),
              ],
            ),
          ),
          // 时长/操作按钮
          ShimmerLoading(
            width: 32,
            height: 32,
            borderRadius: AppTheme.radiusFullPill,
          ),
        ],
      ),
    );
  }
}

/// 歌曲列表骨架屏 — 多首歌曲加载
class SongListShimmer extends StatelessWidget {
  final int itemCount;

  SongListShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => SongCardShimmer(),
      ),
    );
  }
}

/// 网格卡片骨架屏 — 用于歌单/专辑网格
class GridCardShimmer extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final double childAspectRatio;

  GridCardShimmer({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
    this.childAspectRatio = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面
              Expanded(
                child: ShimmerLoading(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: AppTheme.radiusComfortable,
                ),
              ),
              SizedBox(height: 10),
              // 标题
              ShimmerLoading(
                width: double.infinity,
                height: 14,
                borderRadius: AppTheme.radiusSmall,
              ),
              SizedBox(height: 6),
              // 副标题
              ShimmerLoading(
                width: 80,
                height: 10,
                borderRadius: AppTheme.radiusSmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 个人主页骨架屏 — 头像+统计+列表
class ProfileShimmer extends StatelessWidget {
  ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 20),
          // 头像
          ShimmerLoading(
            width: 80,
            height: 80,
            borderRadius: 40,
          ),
          SizedBox(height: 16),
          // 用户名
          Center(
            child: ShimmerLoading(
              width: 120,
              height: 20,
              borderRadius: AppTheme.radiusSmall,
            ),
          ),
          SizedBox(height: 8),
          // 简介
          Center(
            child: ShimmerLoading(
              width: 180,
              height: 14,
              borderRadius: AppTheme.radiusSmall,
            ),
          ),
          SizedBox(height: 24),
          // 统计栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (i) => Column(
                children: [
                  ShimmerLoading(
                    width: 40,
                    height: 20,
                    borderRadius: AppTheme.radiusSmall,
                  ),
                  SizedBox(height: 6),
                  ShimmerLoading(
                    width: 50,
                    height: 12,
                    borderRadius: AppTheme.radiusSmall,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),
          // 列表
          ...List.generate(
            4,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  ShimmerLoading(
                    width: 56,
                    height: 56,
                    borderRadius: AppTheme.radiusMedium,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(
                          width: double.infinity,
                          height: 16,
                        ),
                        SizedBox(height: 6),
                        ShimmerLoading(
                          width: 100,
                          height: 12,
                        ),
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

/// 播放器骨架屏 — 用于播放器页面加载
class PlayerShimmer extends StatelessWidget {
  PlayerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 40),
          // 封面大图
          Center(
            child: ShimmerLoading(
              width: 280,
              height: 280,
              borderRadius: AppTheme.radiusExtraLarge,
            ),
          ),
          SizedBox(height: 32),
          // 歌名
          ShimmerLoading(
            width: 200,
            height: 24,
            borderRadius: AppTheme.radiusSmall,
          ),
          SizedBox(height: 12),
          // 歌手
          ShimmerLoading(
            width: 120,
            height: 16,
            borderRadius: AppTheme.radiusSmall,
          ),
          SizedBox(height: 40),
          // 进度条
          ShimmerLoading(
            width: double.infinity,
            height: 4,
            borderRadius: 2,
          ),
          SizedBox(height: 40),
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
              (i) => ShimmerLoading(
                width: i == 2 ? 64 : 40,
                height: i == 2 ? 64 : 40,
                borderRadius: AppTheme.radiusFullPill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 评论列表骨架屏
class CommentListShimmer extends StatelessWidget {
  final int itemCount;

  CommentListShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              ShimmerLoading(
                width: 36,
                height: 36,
                borderRadius: 18,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 用户名
                    ShimmerLoading(
                      width: 80,
                      height: 14,
                      borderRadius: AppTheme.radiusSmall,
                    ),
                    SizedBox(height: 8),
                    // 评论内容（随机宽度）
                    ShimmerLoading(
                      width: MediaQuery.of(context).size.width * (0.4 + (i % 3) * 0.15),
                      height: 12,
                      borderRadius: AppTheme.radiusSmall,
                    ),
                    SizedBox(height: 6),
                    // 时间
                    ShimmerLoading(
                      width: 60,
                      height: 10,
                      borderRadius: AppTheme.radiusSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
