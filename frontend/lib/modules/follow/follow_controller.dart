import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:aimusic_app/services/api_service.dart';

class FollowController extends GetxController {
  // 0 = 粉丝, 1 = 关注
  final RxInt type = 0.obs;
  final RxInt userId = 0.obs;
  final RxList users = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;

  int _page = 1;
  static const int _pageSize = 20;

  final ApiService _api = Get.find<ApiService>();

  // 本地跟踪关注状态（方便已关注列表页面切换）
  final Map<int, bool> _followedMap = {};

  bool isUserFollowed(int uid) => _followedMap[uid] ?? false;

  void init(int userIdValue, int typeValue) {
    userId.value = userIdValue;
    type.value = typeValue;
    _page = 1;
    hasMore.value = true;
    users.clear();
    _followedMap.clear();
    loadData();
  }

  String get title => type.value == 0 ? '粉丝' : '关注';

  Future<void> loadData() async {
    isLoading.value = true;
    _page = 1;
    try {
      final response = await _fetchUsers();
      final list = _extractList(response);
      users.value = list;
      hasMore.value = list.length >= _pageSize;
      _updateFollowedMap(list);
    } catch (e) {
      debugPrint('加载${title}列表失败: $e');
      users.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    _page = 1;
    try {
      final response = await _fetchUsers();
      final list = _extractList(response);
      users.value = list;
      hasMore.value = list.length >= _pageSize;
      _updateFollowedMap(list);
    } catch (e) {
      debugPrint('刷新${title}列表失败: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    _page++;
    try {
      final response = await _fetchUsers();
      final list = _extractList(response);
      if (list.isEmpty) {
        hasMore.value = false;
      } else {
        users.addAll(list);
        _updateFollowedMap(list);
        hasMore.value = list.length >= _pageSize;
      }
    } catch (e) {
      _page--;
      debugPrint('加载更多${title}失败: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<Map<String, dynamic>> _fetchUsers() async {
    final path = type.value == 0
        ? '/user/followers/${userId.value}'
        : '/user/following/${userId.value}';
    final response = await _api.get(path, queryParameters: {'page': _page, 'page_size': _pageSize});
    return response as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map && data['list'] is List) {
      return (data['list'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  void _updateFollowedMap(List<Map<String, dynamic>> list) {
    for (final user in list) {
      final uid = user['user_id'] ?? user['id'];
      final followed = user['is_followed'] == true || user['is_following'] == true;
      if (uid != null && uid is int) {
        _followedMap[uid] = followed;
      }
    }
  }

  /// 在关注列表页面中切换关注状态
  Future<void> toggleFollowForUser(int targetId) async {
    final currentlyFollowed = _followedMap[targetId] ?? false;
    try {
      if (currentlyFollowed) {
        await _api.post('/user/unfollow/$targetId');
        _followedMap[targetId] = false;
      } else {
        await _api.post('/user/follow/$targetId');
        _followedMap[targetId] = true;
      }
      users.refresh();
    } catch (e) {
      debugPrint('切换关注状态失败: $e');
    }
  }

  void switchType(int newType) {
    if (newType != type.value) {
      type.value = newType;
      _page = 1;
      hasMore.value = true;
      users.clear();
      _followedMap.clear();
      loadData();
    }
  }
}
