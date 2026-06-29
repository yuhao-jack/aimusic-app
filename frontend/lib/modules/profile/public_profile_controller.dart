import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

/// 公开个人主页控制器（他人视角）
/// 加载用户公开信息、作品列表、动态列表，支持关注/取消关注
class PublicProfileController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  /// 目标用户ID
  final RxInt userId = 0.obs;

  /// 用户信息
  final Rxn<Map<String, dynamic>> userInfo = Rxn<Map<String, dynamic>>();

  /// 关注状态
  final RxBool isFollowed = false.obs;
  /// 关注操作加载中
  final RxBool followLoading = false.obs;

  /// 统计数据
  final RxInt followerCount = 0.obs;
  final RxInt followingCount = 0.obs;
  final RxInt workCount = 0.obs;

  /// 页面加载状态
  final RxBool isLoading = true.obs;

  /// Tab 切换：0=作品，1=动态
  final RxInt currentTab = 0.obs;

  /// 作品列表
  final RxList<dynamic> works = <dynamic>[].obs;
  /// 动态列表
  final RxList<dynamic> posts = <dynamic>[].obs;

  /// 加载用户数据
  void loadData(int id) {
    userId.value = id;
    _loadUserProfile();
    _loadFollowStatus();
  }

  /// 加载用户公开资料
  Future<void> _loadUserProfile() async {
    isLoading.value = true;
    try {
      final response = await _api.get('/user/${userId.value}/profile');
      if (response['code'] == 0) {
        final data = response['data'];
        userInfo.value = data;
        followerCount.value = (data['followers_count'] ?? data['follower_count'] ?? 0) as int;
        followingCount.value = (data['following_count'] ?? 0) as int;
        workCount.value = (data['works_count'] ?? 0) as int;
      }
    } catch (e) {
      debugPrint('加载用户资料失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载关注状态
  Future<void> _loadFollowStatus() async {
    try {
      final response = await _api.get(
        '/user/follow/status',
        queryParameters: {'target_ids': '$userId'},
      );
      final data = response['data'];
      if (data != null) {
        final status = data['status'];
        if (status is Map) {
          isFollowed.value = status['$userId'] == true;
        }
      }
    } catch (e) {
      debugPrint('加载关注状态失败: $e');
    }
  }

  /// 加载作品列表
  Future<void> loadWorks() async {
    try {
      final response = await _api.get('/user/${userId.value}/works');
      if (response['code'] == 0) {
        works.value = response['data'] ?? [];
      }
    } catch (e) {
      debugPrint('加载作品列表失败: $e');
    }
  }

  /// 加载动态列表
  Future<void> loadPosts() async {
    try {
      final response = await _api.get('/user/${userId.value}/posts');
      if (response['code'] == 0) {
        posts.value = response['data'] ?? [];
      }
    } catch (e) {
      debugPrint('加载动态列表失败: $e');
    }
  }

  /// 切换关注/取消关注
  Future<void> toggleFollow() async {
    if (followLoading.value) return;
    followLoading.value = true;

    try {
      if (isFollowed.value) {
        await _api.post('/user/unfollow/$userId');
        isFollowed.value = false;
        followerCount.value = (followerCount.value - 1).clamp(0, 999999);
      } else {
        await _api.post('/user/follow/$userId');
        isFollowed.value = true;
        followerCount.value += 1;
      }
    } catch (e) {
      debugPrint('切换关注状态失败: $e');
    } finally {
      followLoading.value = false;
    }
  }

  /// 切换 Tab
  void switchTab(int index) {
    currentTab.value = index;
    if (index == 0 && works.isEmpty) {
      loadWorks();
    } else if (index == 1 && posts.isEmpty) {
      loadPosts();
    }
  }
}
