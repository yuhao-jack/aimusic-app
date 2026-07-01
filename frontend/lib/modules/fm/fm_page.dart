import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/modules/fm/fm_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

/// 私人FM页面 - 全屏播放界面（动画增强版）
/// 动画效果：
/// - 封面模糊背景（BackdropFilter）
/// - 封面旋转动画（播放时旋转，暂停时停止）
/// - 喜欢按钮：心形弹跳动画
/// - 跳过按钮：封面向左滑出+新封面从右滑入
/// - 底部歌曲标题+歌手渐入动画
class FmPage extends StatefulWidget {
  FmPage({super.key});

  @override
  State<FmPage> createState() => _FmPageState();
}

class _FmPageState extends State<FmPage> with TickerProviderStateMixin {
  /// 封面旋转控制器（播放时持续旋转，暂停时停止）
  late AnimationController _rotationController;

  /// 封面滑动控制器（跳过时：旧封面左滑出，新封面右滑入）
  late AnimationController _slideController;
  late Animation<Offset> _slideOutAnimation;
  late Animation<Offset> _slideInAnimation;

  /// 喜欢按钮弹跳控制器
  late AnimationController _likeBounceController;
  late Animation<double> _likeBounceAnimation;

  /// 歌曲信息渐入控制器
  late AnimationController _infoFadeController;
  late Animation<double> _infoFadeAnimation;

  @override
  void initState() {
    super.initState();

    // 封面旋转动画：4秒一圈，循环播放
    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    );

    // 封面滑动动画
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-1.5, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    _slideInAnimation = Tween<Offset>(
      begin: Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    // 喜欢弹跳动画：缩放从0.5弹到1.2再回1.0
    _likeBounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _likeBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _likeBounceController,
      curve: Curves.easeOut,
    ));

    // 歌曲信息渐入动画
    _infoFadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _infoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _infoFadeController, curve: Curves.easeOut),
    );
    _infoFadeController.forward();

    // 监听播放状态控制旋转
    ever(Get.find<FmController>().isPlaying, (bool playing) {
      if (playing) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    // 监听跳过事件
    ever(Get.find<FmController>().isSkipping, (bool skipping) {
      if (skipping) {
        _onSkip();
      }
    });

    // 监听喜欢按钮弹跳
    ever(Get.find<FmController>().likeBounceTrigger, (_) {
      _likeBounceController.forward(from: 0.0);
    });
  }

  /// 跳过动画：旧封面滑出 → 新封面滑入
  void _onSkip() async {
    _infoFadeController.reset();
    await _slideController.forward();
    _slideController.reset();
    Get.find<FmController>().resetSkipState();
    _infoFadeController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _slideController.dispose();
    _likeBounceController.dispose();
    _infoFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 背景模糊效果
          _buildBackground(),
          // 主要内容
          SafeArea(
            child: Column(
              children: [
                // 顶部栏
                _buildTopBar(),
                // 主要内容区域
                Expanded(
                  child: _buildMainContent(),
                ),
                // 控制按钮
                _buildControls(),
                SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 背景模糊效果 - 使用封面图做模糊背景
  Widget _buildBackground() {
    return GetX<FmController>(
      builder: (controller) {
        final coverUrl = controller.currentCoverUrl.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            // 封面模糊背景
            if (coverUrl.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => SizedBox.shrink(),
                ),
              ),
            // 毛玻璃模糊
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            // 暗色覆盖层，确保文字可读
            Container(
              color: AppTheme.surface1.withOpacity(0.6),
            ),
            // 柔和的品牌色渐变叠加
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppTheme.brandIndigo.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // 边缘暗角效果
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.transparent,
                    AppTheme.surface1.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 顶部栏
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios,
                color: AppTheme.textWhite, size: 22),
            onPressed: () => Get.back(),
          ),
          Spacer(),
          Text(
            '私人FM',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  /// 主要内容区域
  Widget _buildMainContent() {
    return GetX<FmController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return _buildFmShimmer();
        }

        if (controller.songQueue.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 20),
              // 封面图片（带旋转+滑动动画）
              _buildCoverArt(controller),
              SizedBox(height: 32),
              // 歌曲信息（带渐入动画）
              _buildSongInfo(controller),
            ],
          ),
        );
      },
    );
  }

  /// FM骨架屏
  Widget _buildFmShimmer() {
    return Column(
      children: [
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 60),
          child: AspectRatio(
            aspectRatio: 1,
            child: ShimmerLoading(
              width: double.infinity,
              height: double.infinity,
              borderRadius: AppTheme.radiusLarge,
            ),
          ),
        ),
        SizedBox(height: 32),
        ShimmerLoading(width: 200, height: 24),
        SizedBox(height: 12),
        ShimmerLoading(width: 120, height: 16),
      ],
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.radio_rounded,
            size: 64,
            color: AppTheme.textDarkGray.withOpacity(0.4),
          ),
          SizedBox(height: 16),
          Text(
            '暂无推荐歌曲',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSilver,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '稍后再来试试吧',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLightGray,
            ),
          ),
        ],
      ),
    );
  }

  /// 封面图片 - 带旋转动画和跳过滑动动画
  Widget _buildCoverArt(FmController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 60),
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedBuilder(
          animation: Listenable.merge([_slideController, _rotationController]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // 旧封面（跳过时向左滑出）
                if (_slideController.isAnimating)
                  SlideTransition(
                    position: _slideOutAnimation,
                    child: _buildCoverImage(controller),
                  ),
                // 当前封面（跳过时从右侧滑入）
                SlideTransition(
                  position: _slideController.isAnimating
                      ? _slideInAnimation
                      : AlwaysStoppedAnimation(Offset.zero),
                  child: _buildRotatingCover(controller),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 旋转封面容器
  Widget _buildRotatingCover(FmController controller) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: child,
        );
      },
      child: _buildCoverImage(controller),
    );
  }

  /// 封面图片构建
  Widget _buildCoverImage(FmController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandIndigo.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: 2,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: controller.currentCoverUrl.value.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: controller.currentCoverUrl.value,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _buildDefaultCover(),
                  errorWidget: (_, __, ___) => _buildDefaultCover(),
                )
              : _buildDefaultCover(),
        ),
      ),
    );
  }

  /// 默认封面
  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brandIndigo, AppTheme.brandPurple],
        ),
      ),
      child: Center(
        child: Icon(Icons.music_note_rounded,
            size: 64, color: Colors.white24),
      ),
    );
  }

  /// 歌曲信息 - 带渐入动画
  Widget _buildSongInfo(FmController controller) {
    return FadeTransition(
      opacity: _infoFadeAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            Text(
              controller.currentTitle.value.isEmpty
                  ? '暂无播放'
                  : controller.currentTitle.value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Text(
              controller.currentArtist.value.isEmpty
                  ? '等待播放'
                  : controller.currentArtist.value,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSilver,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 控制按钮
  Widget _buildControls() {
    final controller = Get.find<FmController>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 不喜欢按钮
          _buildControlButton(
            icon: Icons.thumb_down_outlined,
            color: AppTheme.textLightGray,
            size: 28,
            onTap: controller.dislikeCurrentSong,
          ),
          // 播放/暂停按钮
          Obx(() => ElasticButton(
                onTap: controller.togglePlay,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryToSecondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandIndigo.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppTheme.brandPurple.withOpacity(0.25),
                        blurRadius: 28,
                        spreadRadius: 1,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Icon(
                    controller.isPlaying.value
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: AppTheme.textWhite,
                    size: 36,
                  ),
                ),
              )),
          // 喜欢按钮 - 带弹跳动画
          _buildLikeButton(controller),
        ],
      ),
    );
  }

  /// 喜欢按钮 - 心形弹跳动画
  Widget _buildLikeButton(FmController controller) {
    return GestureDetector(
      onTap: controller.likeCurrentSong,
      child: AnimatedBuilder(
        animation: _likeBounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _likeBounceAnimation.value,
            child: child,
          );
        },
        child: Obx(() => Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                controller.isLiked.value
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 28,
                color: controller.isLiked.value
                    ? AppTheme.brandPink
                    : AppTheme.textLightGray,
              ),
            )),
      ),
    );
  }

  /// 控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return ElasticButton(
      onTap: onTap,
      child: Container(
        width: size + 24,
        height: size + 24,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );
  }
}
