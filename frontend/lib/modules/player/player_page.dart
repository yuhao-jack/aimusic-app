import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/modules/player/player_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/services/playlist_service.dart';
import 'package:aimusic_app/utils/share_util.dart';
import 'package:aimusic_app/utils/poster_util.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';
import 'package:aimusic_app/widgets/lyric_poster.dart';

/// 全屏播放器页面 - 简约毛玻璃科技感
class PlayerPage extends GetView<PlayerController> {
  PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 毛玻璃背景（封面图 + 高斯模糊 + 渐变遮罩）
          _buildBackground(context),
          // 手势层 + 内容
          _buildGestureLayer(
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: Obx(() {
                      if (controller.showLyrics.value) {
                        return _buildLyricsView();
                      }
                      return _buildCoverView();
                    }),
                  ),
                  _buildControls(),
                  SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 毛玻璃背景：封面图 + 高斯模糊 + 渐变遮罩 =====
  Widget _buildBackground(BuildContext context) {
    return Obx(() {
      final themeColor = controller.getThemeColor();
      final coverUrl = controller.currentCoverUrl.value;
      return Stack(
        fit: StackFit.expand,
        children: [
          // 底层：封面图片或主题色渐变
          if (coverUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: themeColor.withOpacity(0.3)),
              errorWidget: (_, __, ___) => Container(color: themeColor.withOpacity(0.3)),
            )
          else
            Container(
              color: themeColor.withOpacity(0.3),
            ),
          // 高斯模糊层
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // 深色渐变遮罩（确保文字可读）
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.surface1.withOpacity(0.6),
                  AppTheme.surface1.withOpacity(0.85),
                  AppTheme.surface1.withOpacity(0.95),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // 径向渐变：主题色微光
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  themeColor.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  // ===== Top Bar =====
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.only(left: 4, right: 8, top: 2),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios,
                color: AppTheme.textWhite, size: 22),
            onPressed: () => Get.back(),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Obx(() => Text(
                  controller.currentSongTitle.value.isEmpty
                      ? '音浪 AI'
                      : controller.currentSongTitle.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.more_vert_rounded,
                color: AppTheme.textSilver, size: 22),
            onPressed: () => _showMoreMenu(),
          ),
        ],
      ),
    );
  }

  // ===== Cover View (rounded corner disc with glow border) =====
  Widget _buildCoverView() {
    // 当前无歌曲信息时显示骨架屏
    if (controller.currentSongTitle.value.isEmpty) {
      return _buildPlayerShimmer();
    }
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 12),
          // Compact disc
          _buildCompactDisc(),
          SizedBox(height: 20),
          // Song info
          _buildSongInfo(),
        ],
      ),
    );
  }

  /// 播放器骨架屏 - 封面+标题+歌手占位
  Widget _buildPlayerShimmer() {
    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 12),
          // 封面占位
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
          SizedBox(height: 28),
          // 标题占位
          ShimmerLoading(width: 180, height: 20),
          SizedBox(height: 10),
          // 歌手占位
          ShimmerLoading(width: 100, height: 14),
        ],
      ),
    );
  }

  Widget _buildCompactDisc() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 60),
      child: AspectRatio(
        aspectRatio: 1,
        child: _RotatingDisc(
          isPlaying: controller.isPlaying,
          coverUrl: controller.currentCoverUrl.value,
          songId: controller.currentSongId.value,
          themeColor: controller.getThemeColor(),
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Obx(() => Text(
                controller.currentSongTitle.value.isEmpty
                    ? '暂无播放'
                    : controller.currentSongTitle.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
          SizedBox(height: 4),
          Obx(() => Text(
                controller.currentArtist.value.isEmpty
                    ? '点击下方播放开始音乐之旅'
                    : controller.currentArtist.value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSilver,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
          // 睡眠定时器剩余时间标签
          Obx(() {
            if (!controller.isSleepTimerActive) return SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandIndigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  border: Border.all(
                    color: AppTheme.brandIndigo.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bedtime_rounded,
                        size: 14, color: AppTheme.brandIndigo),
                    SizedBox(width: 4),
                    Text(
                      '${controller.formattedSleepRemaining} 后停止',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.brandIndigo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===== 歌词视图 - 逐字高亮 =====
  Widget _buildLyricsView() {
    return Obx(() {
      final items = controller.lyrics;
      final themeColor = controller.getThemeColor();
      final currentIndex = controller.currentLyricIndex.value;

      if (items.isEmpty) {
        return Center(
          child: Text('暂无歌词',
              style: TextStyle(color: AppTheme.textSilver)),
        );
      }
      return ListView.builder(
        controller: controller.lyricScrollController,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final isActive = currentIndex == index;
          final isAdjacent = (index == currentIndex - 1 || index == currentIndex + 1);

          // 根据位置确定字号
          double fontSize;
          if (isActive) {
            fontSize = 22;
          } else if (isAdjacent) {
            fontSize = 16;
          } else {
            fontSize = 15;
          }

          // 非当前行使用简单 Text
          if (!isActive) {
            Color textColor;
            if (isAdjacent) {
              textColor = AppTheme.textSilver;
            } else {
              textColor = AppTheme.textLightGray.withOpacity(0.5);
            }
            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(width: 15),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                        height: 1.5,
                      ),
                      child: Text(
                        items[index]['text'] ?? '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // 当前行：逐字高亮
          final text = items[index]['text'] ?? '';
          final progress = controller.charProgress;

          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // 当前行左侧指示器
                Container(
                  width: 3,
                  height: 32,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: themeColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildHighlightedText(text, progress, fontSize, themeColor),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  /// 构建逐字高亮的 RichText
  Widget _buildHighlightedText(
    String text,
    List<double> charProgressList,
    double fontSize,
    Color themeColor,
  ) {
    final chars = text.characters.toList();
    final spans = <TextSpan>[];

    for (int i = 0; i < chars.length; i++) {
      final p = i < charProgressList.length ? charProgressList[i] : 0.0;
      // 已唱过的字：brandIndigo；未唱的字：textLightGray
      final color = p > 0.5 ? themeColor : AppTheme.textLightGray;
      spans.add(TextSpan(
        text: chars[i],
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1.5,
          shadows: p > 0.5
              ? [Shadow(color: themeColor.withOpacity(0.4), blurRadius: 8)]
              : null,
        ),
      ));
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }

  // ===== 手势包装层 =====
  Widget _buildGestureLayer({required Widget child}) {
    return _GesturePlayerWrapper(
      controller: controller,
      child: child,
    );
  }

  // ===== Controls =====
  Widget _buildControls() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          _buildProgressBar(),
          SizedBox(height: 4),
          // Main controls
          _buildMainControls(),
          SizedBox(height: 8),
          // Extra controls
          _buildExtraControls(),
        ],
      ),
    );
  }

  // ===== Progress Bar (thin, gradient) =====
  Widget _buildProgressBar() {
    return Obx(() {
      // 获取当前歌曲的主题色
      final themeColor = controller.getThemeColor();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider
          SizedBox(
            height: 32,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape:
                    RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape:
                    RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: themeColor,
                inactiveTrackColor: AppTheme.borderGray.withOpacity(0.25),
                thumbColor: themeColor,
                overlayColor: themeColor.withOpacity(0.1),
              ),
              child: Slider(
                value: controller.progress.clamp(0.0, 1.0),
                onChanged: (v) => controller.seek(v),
                onChangeEnd: (v) => controller.seek(v),
              ),
            ),
          ),
          // Time labels - compact
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.formattedPosition,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLightGray,
                  ),
                ),
                Text(
                  controller.formattedDuration,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLightGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ===== Main Controls (4 buttons, even distribution) =====
  Widget _buildMainControls() {
    // 获取当前歌曲的主题色
    final themeColor = controller.getThemeColor();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        Obx(() => _buildInlineButton(
              icon: Icons.shuffle_rounded,
              size: 20,
              isActive: controller.isShuffled,
              activeColor: themeColor,
              onTap: controller.toggleShuffle,
            )),
        // Previous
        _buildInlineButton(
          icon: Icons.skip_previous_rounded,
          size: 26,
          onTap: controller.playPrevious,
        ),
        // Play/Pause (56px gradient circle with glow)
        Obx(() => ElasticButton(
              onTap: controller.togglePlay,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [themeColor, themeColor.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: themeColor.withOpacity(0.2),
                      blurRadius: 28,
                      spreadRadius: 1,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Icon(
                  controller.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: AppTheme.textWhite,
                  size: 32,
                ),
              ),
            )),
        // Next
        _buildInlineButton(
          icon: Icons.skip_next_rounded,
          size: 26,
          onTap: controller.playNext,
        ),
        // Repeat
        Obx(() => _buildInlineButton(
              icon: controller.isRepeating
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              size: 20,
              isActive: controller.isRepeating,
              activeColor: themeColor,
              onTap: controller.toggleRepeat,
            )),
      ],
    );
  }

  Widget _buildInlineButton({
    required IconData icon,
    required double size,
    VoidCallback? onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    return ElasticButton(
      onTap: onTap,
      child: Container(
        width: size + 16,
        height: size + 16,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: size,
          color: isActive
              ? (activeColor ?? AppTheme.brandIndigo)
              : Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  // ===== Extra Controls =====
  Widget _buildExtraControls() {
    // 获取当前歌曲的主题色
    final themeColor = controller.getThemeColor();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Like
          Obx(() => LikeButton(
                isLiked: controller.isLiked,
                size: 20,
                activeColor: AppTheme.brandPink,
                onTap: controller.toggleLike,
              )),
          // Lyrics toggle
          _buildExtraInlineButton(
            icon: Icons.lyrics_rounded,
            isActive: controller.showLyrics.value,
            activeColor: themeColor,
            onTap: controller.toggleLyrics,
          ),
          // Playback speed
          Obx(() => ElasticButton(
                onTap: () => _showSpeedPicker(),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: controller.playbackSpeed != 1.0
                        ? themeColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: controller.playbackSpeed != 1.0
                        ? Border.all(
                            color: themeColor.withOpacity(0.3))
                        : null,
                  ),
                  child: Text(
                    '${controller.playbackSpeed}x',
                    style: TextStyle(
                      color: controller.playbackSpeed != 1.0
                          ? themeColor
                          : Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )),
          // Share
          _buildExtraInlineButton(
            icon: Icons.share_rounded,
            onTap: () => _showShareOptions(),
          ),
          // Playlist queue
          _buildExtraInlineButton(
            icon: Icons.queue_music_rounded,
            onTap: () => _showPlayQueue(),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraInlineButton({
    required IconData icon,
    bool isActive = false,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    return ElasticButton(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: isActive
              ? (activeColor ?? AppTheme.brandIndigo)
              : Colors.white.withOpacity(0.55),
        ),
      ),
    );
  }

  void _showSpeedPicker() {
    final speeds = controller.getAvailableSpeeds();
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '播放速度',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: speeds.map((speed) {
                  final isSelected =
                      controller.playbackSpeed == speed;
                  return GestureDetector(
                    onTap: () {
                      controller.setPlaybackSpeed(speed);
                      Get.back();
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.brandIndigo
                            : AppTheme.surface3,
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusFullPill),
                      ),
                      child: Text(
                        '${speed}x',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.textWhite
                              : AppTheme.textSilver,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示分享选项（普通分享或海报分享）
  void _showShareOptions() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '分享',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 24),
              // 普通分享
              _buildMenuOption(
                icon: Icons.share_rounded,
                title: '分享歌曲',
                onTap: () {
                  Get.back();
                  ShareUtil.shareSong(Map<String, dynamic>.from({
                    'title': controller.currentSongTitle.value,
                    'artist': controller.currentArtist.value,
                  }));
                },
              ),
              // 生成海报分享
              _buildMenuOption(
                icon: Icons.image_rounded,
                title: '生成分享海报',
                onTap: () {
                  Get.back();
                  PosterUtil.showPosterPreview(
                    title: controller.currentSongTitle.value,
                    artist: controller.currentArtist.value,
                    coverUrl: controller.currentCoverUrl.value,
                  );
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 更多操作菜单底部面板
  void _showMoreMenu() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部拖拽指示条
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '更多操作',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 24),
              // 睡眠定时器
              _buildMenuOption(
                icon: Icons.bedtime_rounded,
                title: '睡眠定时器',
                onTap: () {
                  Get.back();
                  _showSleepTimerPicker();
                },
              ),
              // 均衡器
              _buildMenuOption(
                icon: Icons.equalizer_rounded,
                title: '均衡器',
                onTap: () {
                  Get.back();
                  _showEqualizerPicker();
                },
              ),
              // 分享
              _buildMenuOption(
                icon: Icons.share_rounded,
                title: '分享',
                onTap: () {
                  Get.back();
                  ShareUtil.shareSong(Map<String, dynamic>.from({
                    'title': controller.currentSongTitle.value,
                    'artist': controller.currentArtist.value,
                  }));
                },
              ),
              // 添加到歌单
              _buildMenuOption(
                icon: Icons.playlist_add_rounded,
                title: '添加到歌单',
                onTap: () {
                  Get.back();
                  _showAddToPlaylist();
                },
              ),
              // 查看歌曲详情
              _buildMenuOption(
                icon: Icons.info_outline_rounded,
                title: '查看歌曲详情',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.musicDetail,
                      arguments: controller.currentSongId.value);
                },
              ),
              // 生成歌词海报
              _buildMenuOption(
                icon: Icons.image_rounded,
                title: '生成歌词海报',
                onTap: () {
                  Get.back();
                  // 获取当前歌词行
                  final lyricIndex = controller.currentLyricIndex.value;
                  final lyrics = controller.lyrics;
                  final currentLyric = lyrics.isNotEmpty && lyricIndex < lyrics.length
                      ? (lyrics[lyricIndex]['text'] ?? '')
                      : controller.currentSongTitle.value;
                  LyricPosterUtil.showLyricPosterPreview(
                    lyric: currentLyric.toString(),
                    title: controller.currentSongTitle.value,
                    artist: controller.currentArtist.value,
                    coverUrl: controller.currentCoverUrl.value,
                  );
                },
              ),
              // 举报
              _buildMenuOption(
                icon: Icons.flag_outlined,
                title: '举报',
                onTap: () {
                  Get.back();
                  _showReportDialog();
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 睡眠定时器选择面板
  void _showSleepTimerPicker() {
    final options = [
      {'label': '关闭', 'minutes': 0},
      {'label': '15 分钟', 'minutes': 15},
      {'label': '30 分钟', 'minutes': 30},
      {'label': '45 分钟', 'minutes': 45},
      {'label': '60 分钟', 'minutes': 60},
    ];
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '睡眠定时器',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 24),
              ...options.map((opt) {
                final minutes = opt['minutes'] as int;
                final isCurrent = minutes == 0
                    ? !controller.isSleepTimerActive
                    : controller.isSleepTimerActive &&
                        controller.sleepTimerRemaining > 0;
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(
                    minutes == 0 ? Icons.timer_off_rounded : Icons.timer_rounded,
                    color: isCurrent ? AppTheme.brandIndigo : AppTheme.textSilver,
                    size: 22,
                  ),
                  title: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      color: isCurrent ? AppTheme.brandIndigo : AppTheme.textWhite,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  trailing: isCurrent
                      ? Icon(Icons.check_rounded,
                          color: AppTheme.brandIndigo, size: 20)
                      : null,
                  onTap: () {
                    controller.setSleepTimer(minutes);
                    Get.back();
                    if (minutes > 0) {
                      Get.snackbar(
                        '睡眠定时器',
                        '$minutes 分钟后自动暂停播放',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppTheme.surface3,
                        colorText: AppTheme.textWhite,
                        duration: Duration(seconds: 2),
                        margin: EdgeInsets.all(16),
                        borderRadius: 12,
                      );
                    }
                  },
                );
              }),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 均衡器选择面板
  void _showEqualizerPicker() {
    final presets = controller.getEqPresets();
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '均衡器',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 24),
              ...presets.map((preset) {
                final isSelected = controller.currentEqPreset == preset;
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(
                    Icons.equalizer_rounded,
                    color: isSelected ? AppTheme.brandIndigo : AppTheme.textSilver,
                    size: 22,
                  ),
                  title: Text(
                    preset,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected ? AppTheme.brandIndigo : AppTheme.textWhite,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded,
                          color: AppTheme.brandIndigo, size: 20)
                      : null,
                  onTap: () {
                    controller.setEqPreset(preset);
                    Get.back();
                    Get.snackbar(
                      '均衡器',
                      '已切换到$preset模式',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppTheme.surface3,
                      colorText: AppTheme.textWhite,
                      duration: Duration(seconds: 2),
                      margin: EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                  },
                );
              }),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建菜单选项行
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: AppTheme.textSilver, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: AppTheme.textWhite,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  /// 播放队列底部面板
  void _showPlayQueue() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            // 顶部拖拽指示条
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textDarkGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            // 标题
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    '播放队列',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  SizedBox(width: 8),
                  Obx(() => Text(
                        '${controller.playList.length}首',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSilver,
                        ),
                      )),
                ],
              ),
            ),
            SizedBox(height: 12),
            // 队列列表
            Obx(() {
              if (controller.playList.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      '暂无播放队列',
                      style: TextStyle(color: AppTheme.textSilver),
                    ),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(Get.context!).size.height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  itemCount: controller.playList.length,
                  itemBuilder: (ctx, index) {
                    final song = controller.playList[index];
                    final isCurrent = controller.currentIndex.value == index;
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 24, vertical: 2),
                      leading: isCurrent
                          ? Icon(Icons.equalizer_rounded,
                              color: AppTheme.brandIndigo, size: 20)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 14,
                              ),
                            ),
                      title: Text(
                        song['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          color: isCurrent
                              ? AppTheme.brandIndigo
                              : AppTheme.textWhite,
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        song['singer'] ?? song['artist'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSilver,
                        ),
                      ),
                      onTap: () {
                        controller.setPlayListAndPlay(
                            controller.playList, index);
                        Get.back();
                      },
                    );
                  },
                ),
              );
            }),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 举报原因选项列表
  static List<String> _reportReasons = [
    '不适当内容',
    '版权侵权',
    '垃圾信息',
    '其他',
  ];

  /// 添加到歌单底部面板
  void _showAddToPlaylist() {
    final playlistService = Get.find<PlaylistService>();
    final RxList<dynamic> playlists = <dynamic>[].obs;
    final RxBool isLoading = true.obs;

    // 加载歌单列表
    playlistService.getUserPlaylists().then((data) {
      if (data != null) playlists.value = data;
      isLoading.value = false;
    });

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部拖拽指示条
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '添加到歌单',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 24),
              Obx(() {
                if (isLoading.value) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.brandIndigo,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                if (playlists.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        '暂无歌单，请先创建歌单',
                        style: TextStyle(color: AppTheme.textSilver),
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(Get.context!).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    itemCount: playlists.length,
                    itemBuilder: (_, index) {
                      final playlist = playlists[index];
                      return ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.brandIndigo.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Icon(
                            Icons.playlist_play_rounded,
                            color: AppTheme.brandIndigo,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          playlist['name'] ?? '未命名歌单',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${playlist['song_count'] ?? 0}首',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSilver,
                          ),
                        ),
                        onTap: () async {
                          final playlistId = playlist['id'];
                          final songId = controller.currentSongId.value;
                          if (playlistId != null && songId > 0) {
                            await playlistService.addSongToPlaylist(
                              playlistId: playlistId is int
                                  ? playlistId
                                  : (playlistId as num).toInt(),
                              songId: songId,
                            );
                            Get.back();
                          }
                        },
                      );
                    },
                  ),
                );
              }),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示举报原因选择对话框
  void _showReportDialog() {
    showDialog(
      context: Get.context!,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '举报',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // 举报原因选项列表
              ...List.generate(_reportReasons.length, (index) {
                final reason = _reportReasons[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showReportDetailDialog(reason);
                    },
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 14, horizontal: 8),
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示举报详情输入对话框
  void _showReportDetailDialog(String reason) {
    final detailController = TextEditingController();
    showDialog(
      context: Get.context!,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '举报 - $reason',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextField(
                controller: detailController,
                maxLines: 3,
                style: TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: '请补充说明（选填）',
                  hintStyle:
                      TextStyle(color: AppTheme.textDarkGray),
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusComfortable),
                    borderSide:
                        BorderSide(color: AppTheme.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusComfortable),
                    borderSide:
                        BorderSide(color: AppTheme.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusComfortable),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppTheme.textWhite,
                        elevation: 0,
                        padding:
                            EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusFullPill),
                          side: BorderSide(
                              color: AppTheme.borderGray),
                        ),
                      ),
                      child: Text('取消'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ToastUtil.success('举报已提交，我们会尽快处理');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.textWhite,
                        elevation: 0,
                        padding:
                            EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusFullPill),
                        ),
                      ),
                      child: Text('提交'),
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

/// 旋转封面光盘组件 - 播放时缓慢旋转，暂停时停止
class _RotatingDisc extends StatefulWidget {
  final bool isPlaying;
  final String coverUrl;
  final int songId;
  final Color themeColor;

  _RotatingDisc({
    required this.isPlaying,
    required this.coverUrl,
    required this.songId,
    required this.themeColor,
  });

  @override
  State<_RotatingDisc> createState() => _RotatingDiscState();
}

class _RotatingDiscState extends State<_RotatingDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // 一圈20秒，匀速旋转
    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    );
    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _RotatingDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 播放状态变化时启动或停止旋转
    if (widget.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.themeColor;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow border - 使用动态主题色
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 2,
                offset: Offset(0, 8),
              ),
            ],
          ),
        ),
        // 封面图 - 带旋转动画，Hero 共享元素过渡
        Hero(
          tag: 'song_cover_${widget.songId}',
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * 3.141592653589793,
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: widget.coverUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildDefaultCover(),
                        errorWidget: (_, __, ___) => _buildDefaultCover(),
                      )
                    : _buildDefaultCover(),
              ),
            ),
          ),
        ),
        // Glass overlay on cover for depth
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.03),
                    Colors.transparent,
                    Colors.black.withOpacity(0.06),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
}

/// 手势操作包装层
/// 左滑下一首、右滑上一首、下滑关闭、双击点赞、长按倍速
class _GesturePlayerWrapper extends StatefulWidget {
  final PlayerController controller;
  final Widget child;

  _GesturePlayerWrapper({
    required this.controller,
    required this.child,
  });

  @override
  State<_GesturePlayerWrapper> createState() => _GesturePlayerWrapperState();
}

class _GesturePlayerWrapperState extends State<_GesturePlayerWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  // 水平滑动偏移量 (-1.0 ~ 1.0)
  double _dragOffsetX = 0.0;
  // 垂直滑动偏移量 (0.0 ~ 1.0)
  double _dragOffsetY = 0.0;
  // 长按状态
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  /// 处理水平滑动结束
  void _handleHorizontalDragEnd(double velocity) {
    final threshold = 0.25;
    if (_dragOffsetX < -threshold || velocity < -800) {
      _animateOut(() => widget.controller.playNext());
    } else if (_dragOffsetX > threshold || velocity > 800) {
      _animateOut(() => widget.controller.playPrevious());
    } else {
      _animateReset();
    }
  }

  /// 处理垂直滑动结束
  void _handleVerticalDragEnd() {
    if (_dragOffsetY > 0.2) {
      Get.back();
    } else {
      _animateReset();
    }
  }

  /// 滑出动画后执行回调
  void _animateOut(VoidCallback onComplete) {
    _slideController.forward().then((_) {
      onComplete();
      _slideController.reset();
      setState(() {
        _dragOffsetX = 0.0;
        _dragOffsetY = 0.0;
      });
    });
  }

  /// 回弹动画
  void _animateReset() {
    _slideController.forward().then((_) {
      _slideController.reset();
      setState(() {
        _dragOffsetX = 0.0;
        _dragOffsetY = 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // 双击点赞 + 长按倍速（不与滚动冲突）
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        widget.controller.toggleLike();
        ToastUtil.success(widget.controller.isLiked ? '已点赞' : '已取消点赞');
      },
      onLongPressStart: (_) {
        setState(() => _isLongPressing = true);
        widget.controller.setPlaybackSpeed(2.0);
      },
      onLongPressEnd: (_) {
        setState(() => _isLongPressing = false);
        widget.controller.setPlaybackSpeed(1.0);
      },
      // 水平滑动（左右切换歌曲）
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _dragOffsetX += details.delta.dx / MediaQuery.of(context).size.width;
            _dragOffsetX = _dragOffsetX.clamp(-1.0, 1.0);
          });
        },
        onHorizontalDragEnd: (details) {
          _handleHorizontalDragEnd(details.velocity.pixelsPerSecond.dx);
        },
        child: Stack(
          children: [
            // 下滑关闭：在顶部区域添加专属手势检测
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 0) {
                    setState(() {
                      _dragOffsetY += details.delta.dy / MediaQuery.of(context).size.height;
                      _dragOffsetY = _dragOffsetY.clamp(0.0, 1.0);
                    });
                  }
                },
                onVerticalDragEnd: (_) => _handleVerticalDragEnd(),
              ),
            ),
            // 主内容（带滑动偏移动画）
            AnimatedBuilder(
              animation: _slideController,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_slideController.value);
                final offsetX = _dragOffsetX * (1.0 - t);
                final offsetY = _dragOffsetY * (1.0 - t);
                final opacity = 1.0 - (_dragOffsetX.abs() + _dragOffsetY).clamp(0.0, 0.5);

                return Transform.translate(
                  offset: Offset(
                    offsetX * MediaQuery.of(context).size.width,
                    offsetY * MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: Opacity(
                    opacity: opacity,
                    child: widget.child,
                  ),
                );
              },
            ),
            // 长按倍速提示
            if (_isLongPressing)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.brandIndigo.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(
                          AppTheme.radiusFullPill),
                    ),
                    child: Text(
                      '2.0x 倍速播放中',
                      style: TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
