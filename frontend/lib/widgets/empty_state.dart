import 'package:flutter/material.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

/// 通用空状态组件 — 带插画图标和引导按钮
/// 用于替换项目中所有简单的 "暂无xxx" 文字提示
class EmptyStateWidget extends StatelessWidget {
  /// 插画图标
  final IconData icon;

  /// 标题文字
  final String title;

  /// 描述文字（可选）
  final String? description;

  /// 引导按钮文字（可选，如 "去发现"、"去创作"）
  final String? actionText;

  /// 引导按钮点击回调
  final VoidCallback? onAction;

  /// 次要按钮文字（可选）
  final String? secondaryActionText;

  /// 次要按钮点击回调
  final VoidCallback? onSecondaryAction;

  /// 图标大小
  final double iconSize;

  /// 自定义图标颜色
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.iconSize = 80,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 插画图标容器 — 带渐变背景光晕
            FadeInWidget(
              delayMs: 100,
              child: Container(
                width: iconSize + 40,
                height: iconSize + 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (iconColor ?? AppTheme.brandIndigo).withValues(alpha: 0.08),
                      (iconColor ?? AppTheme.brandIndigo).withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: AppTheme.surface3.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(iconSize / 3),
                      border: Border.all(
                        color: AppTheme.borderSubtle.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: iconSize * 0.5,
                      color: iconColor ?? AppTheme.textDarkGray.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 标题
            FadeInWidget(
              delayMs: 200,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSilver,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // 描述
            if (description != null) ...[
              const SizedBox(height: 8),
              FadeInWidget(
                delayMs: 300,
                child: Text(
                  description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLightGray,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            // 引导按钮
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 28),
              FadeInWidget(
                delayMs: 400,
                child: _buildActionButton(
                  text: actionText!,
                  onPressed: onAction!,
                  isPrimary: true,
                ),
              ),
            ],
            // 次要按钮
            if (secondaryActionText != null && onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              FadeInWidget(
                delayMs: 500,
                child: _buildActionButton(
                  text: secondaryActionText!,
                  onPressed: onSecondaryAction!,
                  isPrimary: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建引导按钮
  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryToSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandIndigo.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppTheme.textWhite,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.brandIndigo,
        side: BorderSide(
          color: AppTheme.brandIndigo.withValues(alpha: 0.3),
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 预设的空状态场景 — 快速创建常用空状态
class EmptyStates {
  /// 暂无作品
  static Widget noWorks({VoidCallback? onCreate}) {
    return EmptyStateWidget(
      icon: Icons.music_note_outlined,
      title: '暂无作品',
      description: '还没有创作过歌曲\n去创作你的第一首歌吧',
      actionText: '去创作',
      onAction: onCreate,
    );
  }

  /// 暂无歌单
  static Widget noPlaylists({VoidCallback? onCreate}) {
    return EmptyStateWidget(
      icon: Icons.playlist_play_rounded,
      title: '暂无歌单',
      description: '创建歌单，收藏你喜欢的歌曲',
      actionText: '创建歌单',
      onAction: onCreate,
    );
  }

  /// 暂无评论
  static Widget noComments() {
    return const EmptyStateWidget(
      icon: Icons.chat_bubble_outline_rounded,
      title: '暂无评论',
      description: '快来抢沙发吧~',
    );
  }

  /// 暂无动态
  static Widget noPosts({VoidCallback? onCreate}) {
    return EmptyStateWidget(
      icon: Icons.article_outlined,
      title: '暂无动态',
      description: '分享你的音乐创作和心情',
      actionText: '发动态',
      onAction: onCreate,
    );
  }

  /// 暂无关注
  static Widget noFollowing({VoidCallback? onDiscover}) {
    return EmptyStateWidget(
      icon: Icons.people_outline_rounded,
      title: '暂无关注',
      description: '去发现有趣的创作者吧',
      actionText: '去发现',
      onAction: onDiscover,
    );
  }

  /// 暂无粉丝
  static Widget noFollowers() {
    return const EmptyStateWidget(
      icon: Icons.people_outline_rounded,
      title: '暂无粉丝',
      description: '发布优质内容吸引粉丝关注',
    );
  }

  /// 暂无历史
  static Widget noHistory({VoidCallback? onExplore}) {
    return EmptyStateWidget(
      icon: Icons.history_rounded,
      title: '暂无播放记录',
      description: '去听点好听的音乐吧',
      actionText: '去发现',
      onAction: onExplore,
    );
  }

  /// 暂无喜欢
  static Widget noLikes({VoidCallback? onExplore}) {
    return EmptyStateWidget(
      icon: Icons.favorite_border_rounded,
      title: '暂无喜欢的歌曲',
      description: '遇到喜欢的歌曲，点个心吧',
      actionText: '去发现',
      onAction: onExplore,
    );
  }

  /// 暂无挑战
  static Widget noChallenges() {
    return const EmptyStateWidget(
      icon: Icons.emoji_events_outlined,
      title: '暂无挑战',
      description: '新的挑战即将开始，敬请期待',
    );
  }

  /// 搜索无结果
  static Widget noSearchResults({String? keyword}) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: '未找到相关内容',
      description: keyword != null ? '没有找到与"$keyword"相关的结果\n换个关键词试试吧' : '换个关键词试试吧',
    );
  }

  /// 网络错误
  static Widget networkError({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_rounded,
      title: '网络连接失败',
      description: '请检查网络设置后重试',
      actionText: '重试',
      onAction: onRetry,
      iconColor: AppTheme.warningColor,
    );
  }

  /// 加载失败
  static Widget loadFailed({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.error_outline_rounded,
      title: '加载失败',
      description: '数据加载出错了，请稍后重试',
      actionText: '重试',
      onAction: onRetry,
      iconColor: AppTheme.errorColor,
    );
  }
}
