import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

class CreatorController extends GetxController {
  final RxInt userId = 0.obs;
  final Rxn<Map<String, dynamic>> creator = Rxn<Map<String, dynamic>>();
  final RxBool isFollowed = false.obs;
  final RxInt followerCount = 0.obs;
  final RxInt followingCount = 0.obs;
  final RxInt workCount = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool followLoading = false.obs;

  // Tab 切换
  final RxInt currentTabIndex = 0.obs;

  // 作品列表
  final RxList songs = <dynamic>[].obs;
  // 动态列表
  final RxList posts = <dynamic>[].obs;
  // 歌单列表
  final RxList playlists = <dynamic>[].obs;

  final ApiService _api = Get.find<ApiService>();

  void loadData(int id) {
    userId.value = id;
    _loadCreatorDetail();
    _loadFollowStatus();
  }

  Future<void> _loadCreatorDetail() async {
    isLoading.value = true;
    try {
      final response = await _api.get('/creator/$id');
      final data = response['data'];
      if (data != null) {
        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          creator.value = user;
          followerCount.value = (user['followers_count'] ?? user['follower_count'] ?? 0) as int;
          followingCount.value = (user['following_count'] ?? 0) as int;
          workCount.value = (user['works_count'] ?? 0) as int;
        }
        songs.value = (data['songs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        posts.value = (data['posts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        playlists.value = (data['playlists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }
    } catch (e) {
      debugPrint('加载创作者详情失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadFollowStatus() async {
    try {
      // 后端使用批量查询接口，通过 target_ids 参数传递
      final response = await _api.get('/user/follow/status', queryParameters: {'target_ids': '${userId.value}'});
      final data = response['data'];
      if (data != null) {
        final status = data['status'];
        if (status is Map) {
          isFollowed.value = status['${userId.value}'] == true;
        }
      }
    } catch (e) {
      debugPrint('加载关注状态失败: $e');
    }
  }

  Future<void> toggleFollow() async {
    if (followLoading.value) return;
    followLoading.value = true;

    try {
      if (isFollowed.value) {
        await _api.post('/user/unfollow/${userId.value}');
        isFollowed.value = false;
        followerCount.value = (followerCount.value - 1).clamp(0, 999999);
      } else {
        await _api.post('/user/follow/${userId.value}');
        isFollowed.value = true;
        followerCount.value += 1;
      }
    } catch (e) {
      debugPrint('切换关注状态失败: $e');
    } finally {
      followLoading.value = false;
    }
  }

  void switchTab(int index) {
    currentTabIndex.value = index;
  }

  int get id => userId.value;
}
