import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 统一的卡片组件库
/// 使用新的分层 surface 体系：surface2（基础卡）→ surface3（交互区）→ surfaceElevated（悬浮）
class AppCards {
  // ===== 基础卡片 =====
  static Widget basic({
    required Widget child,
    EdgeInsets? padding,
    double? height,
    double? width,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    final card = Container(
      width: width,
      height: height,
      padding: padding ?? EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(
          color: AppTheme.borderSubtle.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          child: card,
        ),
      );
    }

    return card;
  }

  // ===== 音乐卡片 =====
  static Widget music({
    String? cover,
    required String title,
    String? artist,
    String? style,
    int? playCount,
    VoidCallback? onTap,
    Widget? trailing,
    double? width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ),
                    ),
                    child: cover != null && cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.midDark,
                              child: Icon(
                                Icons.music_note,
                                color: AppTheme.textDarkGray,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.midDark,
                              child: Icon(
                                Icons.music_note,
                                color: AppTheme.textDarkGray,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (style != null && style.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.midDark,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                style,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSilver,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              artist ?? '未知歌手',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSilver,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Play count or trailing
                if (trailing != null)
                  trailing
                else if (playCount != null)
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: AppTheme.textLightGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatPlayCount(playCount),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLightGray,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== 歌单卡片 =====
  static Widget playlist({
    String? cover,
    required String title,
    String? description,
    int? songCount,
    VoidCallback? onTap,
    double width = 160,
  }) {
    final descWidget = description != null && description.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSilver,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : null;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                        ),
                      ),
                      child: cover != null && cover.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: cover,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.midDark,
                                child: Icon(Icons.music_note_rounded,
                                    color: AppTheme.textDarkGray),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.midDark,
                                child: Icon(Icons.music_note_rounded,
                                    color: AppTheme.textDarkGray),
                              ),
                            )
                          : Icon(Icons.music_note_rounded,
                              size: 36, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Description
                if (descWidget != null) descWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== 创作明星卡片 =====
  static Widget creator({
    required String nickname,
    int worksCount = 0,
    int fansCount = 0,
    String? avatar,
    String? style,
    VoidCallback? onTap,
    VoidCallback? onViewTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: avatar != null && avatar.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatar,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.person_rounded,
                            size: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                // Name
                Text(
                  nickname,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (style != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        child: Text(
                          style,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '$worksCount 作品',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSilver,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== 格式化播放数 =====
  static String _formatPlayCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }
}
