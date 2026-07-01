import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/modules/notification/notification_controller.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

class NotificationPage extends StatefulWidget {
  NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with AutomaticKeepAliveClientMixin {
  final NotificationController controller = Get.find<NotificationController>();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingView();
        }

        if (controller.notifications.isEmpty) {
          return _buildEmptyView();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.surface3,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: controller.notifications.length + (controller.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.notifications.length) {
                return _buildLoadingIndicator();
              }
              return FadeInWidget(
                delayMs: (index % 20) * 50,
                child: _buildNotificationItem(controller.notifications[index]),
              );
            },
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface1,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textWhite),
        onPressed: () => Get.back(),
      ),
      title: Text(
        '消息通知',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textWhite),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: controller.markAllAsRead,
          child: Text(
            '全部已读',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(Map n) {
    final id = n['id'] as int? ?? 0;
    final isRead = n['is_read'] == true;
    final type = n['type']?.toString();
    final icon = NotificationController.getIconForType(type);
    final color = NotificationController.getColorForType(type);
    final text = NotificationController.getNotificationText(n);
    final time = n['created_at']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: ElasticButton(
        onTap: () {
          if (!isRead) controller.markAsRead(id);
          _handleNotificationTap(n);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isRead ? AppTheme.surface3 : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(
              color: isRead ? AppTheme.borderGray.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.15),
              width: isRead ? 0.5 : 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Unread dot
                          if (!isRead)
                            Padding(
                              padding: EdgeInsets.only(top: 6, right: 6),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                                color: isRead ? AppTheme.textSilver : AppTheme.textWhite,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      if (n['actor_avatar'] != null && n['actor_avatar'].toString().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: n['actor_avatar'],
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => SizedBox.shrink(),
                                ),
                              ),
                              SizedBox(width: 6),
                            ],
                          ),
                        ),
                      Text(
                        _formatTime(time),
                        style: TextStyle(fontSize: 11, color: AppTheme.textMediumGray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 根据通知类型跳转到对应页面
  void _handleNotificationTap(Map n) {
    final type = n['type']?.toString();
    final resourceId = n['resource_id'];
    final targetType = n['target_type']?.toString();

    switch (type) {
      case 'like':
      case 'favorite':
        // 根据目标类型决定跳转：歌曲→歌曲详情，动态→动态详情
        if (targetType == 'song') {
          Get.toNamed(AppRoutes.musicDetail, arguments: resourceId);
        } else {
          Get.toNamed(AppRoutes.post, arguments: resourceId);
        }
        break;
      case 'follow':
        // 关注通知跳转到用户主页
        final actorId = n['actor_id'] ?? resourceId;
        Get.toNamed(AppRoutes.publicProfile, arguments: actorId);
        break;
      case 'comment':
      case 'reply':
        // 评论/回复通知跳转到动态详情
        Get.toNamed(AppRoutes.post, arguments: resourceId);
        break;
      default:
        break;
    }
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          8,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 40, height: 40, borderRadius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(width: double.infinity, height: 16),
                      SizedBox(height: 6),
                      ShimmerLoading(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: FadeInWidget(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppTheme.textDarkGray.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16),
            Text(
              '暂时没有新消息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSilver,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '当有人与你互动时，会显示在这里',
              style: TextStyle(fontSize: 13, color: AppTheme.textLightGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    return time;
  }
}
