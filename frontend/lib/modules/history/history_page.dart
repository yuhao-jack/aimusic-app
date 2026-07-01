import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/modules/history/history_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

class HistoryPage extends GetView<HistoryController> {
  HistoryPage({super.key});

  String _formatPlayTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Text(
          '播放历史',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textWhite,
          ),
        ),
        actions: [
          Obx(() {
            if (controller.histories.isEmpty) {
              return SizedBox.shrink();
            }
            return TextButton(
              onPressed: () {
                _showClearConfirmDialog(context);
              },
              child: Text(
                '清空',
                style: TextStyle(
                  color: AppTheme.textLightGray,
                  fontSize: 14,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return PageShimmer(itemCount: 8);
        }

        if (controller.histories.isEmpty) {
          return FadeInWidget(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 80,
                    color: AppTheme.textDarkGray.withValues(alpha: 0.4),
                  ),
                  SizedBox(height: 24),
                  Text(
                    '还没有播放记录',
                    style: TextStyle(
                      color: AppTheme.textSilver,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '去发现好音乐吧',
                    style: TextStyle(
                      color: AppTheme.textLightGray,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 28),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: () => Get.offAllNamed(AppRoutes.home),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: AppTheme.textWhite,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusFullPill),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '去发现',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadHistories(),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: controller.histories.length,
            itemBuilder: (context, index) {
              final item = controller.histories[index];
              final song = item['song'] ?? {};
              return _buildHistoryItem(item, song, index);
            },
          ),
        );
      }),
    );
  }

  Widget _buildHistoryItem(dynamic item, Map song, int index) {
    return FadeInWidget(
      delayMs: index * 40,
      child: Dismissible(
        key: Key(item['id'].toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppTheme.errorColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Icon(
            Icons.delete_outline,
            color: AppTheme.textWhite,
          ),
        ),
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmDialog(Get.context!);
        },
        onDismissed: (direction) {
          controller.removeHistory(item['id']);
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: InkWell(
              onTap: () {
                Get.toNamed(AppRoutes.player, arguments: song);
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      child: CachedNetworkImage(
                        imageUrl: song['cover'] ?? '',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.surface3,
                          child: Icon(
                            Icons.music_note,
                            color: AppTheme.textDarkGray,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.surface3,
                          child: Icon(
                            Icons.music_note,
                            color: AppTheme.textDarkGray,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song['title'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                song['singer'] ?? song['artist'] ?? '',
                                style: TextStyle(
                                  color: AppTheme.textSilver,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '·',
                                style: TextStyle(
                                  color: AppTheme.textLightGray,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                _formatPlayTime(item['played_at'] ?? 0),
                                style: TextStyle(
                                  color: AppTheme.textLightGray,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.more_vert_rounded,
                      color: AppTheme.textLightGray,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface3,
        title: Text(
          '删除记录',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '确定要删除这条播放记录吗？',
          style: TextStyle(color: AppTheme.textLightGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '取消',
              style: TextStyle(color: AppTheme.textLightGray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '删除',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface3,
        title: Text(
          '清空历史',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '确定要清空所有播放历史吗？此操作不可恢复。',
          style: TextStyle(color: AppTheme.textLightGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: AppTheme.textLightGray),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.clearHistory();
            },
            child: Text(
              '清空',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
