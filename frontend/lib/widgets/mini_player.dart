import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/modules/player/player_controller.dart';
import 'package:aimusic_app/routes/app_routes.dart';

/// 迷你播放条 - 显示在底部导航栏上方
/// 当有歌曲播放时展示歌曲信息和播放控制
class MiniPlayer extends StatelessWidget {
  MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Get.find<PlayerController>();

    return Obx(() {
      // 没有歌曲时隐藏
      if (player.currentSongTitle.value.isEmpty) {
        return SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.player),
        child: Container(
          height: AppTheme.miniPlayerHeight,
          decoration: BoxDecoration(
            color: AppTheme.surface2.withOpacity(0.95),
            border: Border(
              top: BorderSide(
                color: AppTheme.borderSubtle.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // 进度条
              Obx(() => LinearProgressIndicator(
                value: player.progress,
                backgroundColor: AppTheme.borderSubtle.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandIndigo),
                minHeight: 2,
              )),
              // 内容区
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // 歌曲封面
                      _buildCover(player),
                      SizedBox(width: 12),
                      // 歌曲信息
                      Expanded(child: _buildSongInfo(player)),
                      // 播放/暂停按钮
                      _buildPlayButton(player),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 构建歌曲封面
  Widget _buildCover(PlayerController player) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: CachedNetworkImage(
        imageUrl: player.currentCoverUrl.value,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 40,
          height: 40,
          color: AppTheme.surface3,
          child: Icon(Icons.music_note, size: 20, color: AppTheme.textLightGray),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 40,
          height: 40,
          color: AppTheme.surface3,
          child: Icon(Icons.music_note, size: 20, color: AppTheme.textLightGray),
        ),
      ),
    );
  }

  /// 构建歌曲信息
  Widget _buildSongInfo(PlayerController player) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 歌曲标题
        Obx(() => Text(
          player.currentSongTitle.value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
        SizedBox(height: 2),
        // 歌手名
        Obx(() => Text(
          player.currentArtist.value,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSilver,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
      ],
    );
  }

  /// 构建播放/暂停按钮
  Widget _buildPlayButton(PlayerController player) {
    return Obx(() => ElasticButton(
      onTap: player.togglePlay,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primaryToSecondary,
        ),
        child: Icon(
          player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 22,
          color: AppTheme.textWhite,
        ),
      ),
    ));
  }
}
