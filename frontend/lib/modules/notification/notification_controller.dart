import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/theme/app_theme.dart';

class NotificationController extends GetxController {
  final RxList notifications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxInt unreadCount = 0.obs;

  int _page = 1;
  static const int _pageSize = 20;

  final ApiService _api = Get.find<ApiService>();

  @override
  void onInit() {
    super.onInit();
    loadData();
    loadUnreadCount();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    _page = 1;
    try {
      final response = await _api.get('/notifications', queryParameters: {'page': _page, 'page_size': _pageSize});
      final list = _extractList(response);
      notifications.value = list;
      hasMore.value = list.length >= _pageSize;
    } catch (e) {
      debugPrint('加载通知失败: $e');
      notifications.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    _page = 1;
    try {
      final response = await _api.get('/notifications', queryParameters: {'page': _page, 'page_size': _pageSize});
      final list = _extractList(response);
      notifications.value = list;
      hasMore.value = list.length >= _pageSize;
      loadUnreadCount();
    } catch (e) {
      debugPrint('刷新通知失败: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    _page++;
    try {
      final response = await _api.get('/notifications', queryParameters: {'page': _page, 'page_size': _pageSize});
      final list = _extractList(response);
      if (list.isEmpty) {
        hasMore.value = false;
      } else {
        notifications.addAll(list);
        hasMore.value = list.length >= _pageSize;
      }
    } catch (e) {
      _page--;
      debugPrint('加载更多通知失败: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.put('/notifications/$id/read');
      final index = notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        notifications[index]['is_read'] = true;
        notifications.refresh();
      }
      loadUnreadCount();
    } catch (e) {
      debugPrint('标记已读失败: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.put('/notifications/read-all');
      for (final n in notifications) {
        n['is_read'] = true;
      }
      notifications.refresh();
      unreadCount.value = 0;
    } catch (e) {
      debugPrint('标记全部已读失败: $e');
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _api.get('/notifications/unread-count');
      final data = response['data'];
      if (data is Map) {
        unreadCount.value = (data['unread_count'] ?? data['count'] ?? 0) as int;
      } else if (data is int) {
        unreadCount.value = data;
      }
    } catch (e) {
      debugPrint('加载未读数量失败: $e');
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic response) {
    if (response is Map) {
      final data = response['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['list'] is List) return (data['list'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// 根据通知类型获取图标
  static IconData getIconForType(String? type) {
    switch (type) {
      case 'like':
      case 'favorite':
        return Icons.favorite_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'reply':
        return Icons.reply_rounded;
      case 'system':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  /// 根据通知类型获取颜色
  static Color getColorForType(String? type) {
    switch (type) {
      case 'like':
      case 'favorite':
        return const Color(0xFFEF4444);
      case 'follow':
        return AppTheme.brandPurple;
      case 'comment':
        return const Color(0xFF10B981);
      case 'reply':
        return const Color(0xFFF59E0B);
      default:
        return AppTheme.primaryColor;
    }
  }

  /// 格式化通知文本
  static String getNotificationText(Map n) {
    final type = n['type']?.toString();
    final actor = n['actor_name'] ?? n['sender_name'] ?? '';
    final target = n['target_title'] ?? n['resource_title'] ?? '';

    switch (type) {
      case 'like':
      case 'favorite':
        return '$actor 赞了你的歌曲《$target》';
      case 'follow':
        return '$actor 关注了你';
      case 'comment':
        return '$actor 评论了你的动态';
      case 'reply':
        return '$actor 回复了你的评论';
      default:
        return n['content']?.toString() ?? n['message']?.toString() ?? '';
    }
  }
}
