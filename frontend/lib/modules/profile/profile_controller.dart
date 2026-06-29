import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aimusic_app/global/user_controller.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/utils/toast_util.dart';

class ProfileController extends GetxController {
  final UserController _userController = UserController.to;
  final ApiService _api = Get.find<ApiService>();

  // User info
  Map<String, dynamic> get userInfo => _userController.userInfo;
  bool get isLogin => _userController.isLogin;

  // UI state
  RxInt selectedTab = 0.obs;
  RxBool isLoading = false.obs;

  // Data lists
  RxList<Map<String, dynamic>> myWorks = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> likedSongs = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> playlists = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> drafts = <Map<String, dynamic>>[].obs;

  // 成就相关数据
  RxInt consecutiveCheckInDays = 0.obs; // 连续签到天数
  RxInt fmUsageCount = 0.obs; // FM使用次数
  RxInt shareCount = 0.obs; // 分享次数
  RxInt collectedSongsCount = 0.obs; // 收藏歌曲数

  @override
  void onInit() {
    super.onInit();
    if (isLogin) {
      loadAllData();
    }
  }

  // Load all data from API
  Future<void> loadAllData() async {
    await Future.wait([
      loadMyWorks(),
      loadLikedSongs(),
      loadPlaylists(),
      loadLocalStats(),
    ]);
  }

  // 加载本地统计数据
  Future<void> loadLocalStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取连续签到天数
      final checkedDates = prefs.getStringList('checked_in_dates') ?? [];
      consecutiveCheckInDays.value = _calculateConsecutiveDays(checkedDates);
      
      // 获取FM使用次数
      fmUsageCount.value = prefs.getInt('fm_usage_count') ?? 0;
      
      // 获取分享次数
      shareCount.value = prefs.getInt('share_count') ?? 0;
      
      // 获取收藏歌曲数
      collectedSongsCount.value = prefs.getInt('collected_songs_count') ?? 0;
    } catch (e) {
      debugPrint('加载本地统计数据失败: $e');
    }
  }

  // 计算连续签到天数
  int _calculateConsecutiveDays(List<String> checkedDates) {
    if (checkedDates.isEmpty) return 0;

    int consecutive = 0;
    final today = DateTime.now();
    final todayStr = today.toString().substring(0, 10);

    DateTime checkDate = checkedDates.contains(todayStr)
        ? today
        : today.subtract(const Duration(days: 1));

    while (true) {
      final dateStr = checkDate.toString().substring(0, 10);
      if (checkedDates.contains(dateStr)) {
        consecutive++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return consecutive;
  }

  // 增加FM使用次数
  Future<void> incrementFMUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('fm_usage_count') ?? 0;
      await prefs.setInt('fm_usage_count', currentCount + 1);
      fmUsageCount.value = currentCount + 1;
    } catch (e) {
      debugPrint('更新FM使用次数失败: $e');
    }
  }

  // 增加分享次数
  Future<void> incrementShareCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('share_count') ?? 0;
      await prefs.setInt('share_count', currentCount + 1);
      shareCount.value = currentCount + 1;
    } catch (e) {
      debugPrint('更新分享次数失败: $e');
    }
  }

  // 更新收藏歌曲数
  Future<void> updateCollectedSongsCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('collected_songs_count', count);
      collectedSongsCount.value = count;
    } catch (e) {
      debugPrint('更新收藏歌曲数失败: $e');
    }
  }

  // Load my works
  Future<void> loadMyWorks() async {
    try {
      isLoading.value = true;
      final response = await _api.get('/user/works');
      if (response['code'] == 0) {
        myWorks.value = List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
    } catch (e) {
      debugPrint('加载作品失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load liked songs
  Future<void> loadLikedSongs() async {
    try {
      final response = await _api.get('/user/likes');
      if (response['code'] == 0) {
        likedSongs.value = List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
    } catch (e) {
      debugPrint('加载喜欢失败: $e');
    }
  }

  // Load playlists
  Future<void> loadPlaylists() async {
    try {
      final response = await _api.get('/playlist/list');
      if (response['code'] == 0) {
        final data = response['data'];
        if (data is Map && data['list'] is List) {
          playlists.value = List<Map<String, dynamic>>.from(data['list']);
        } else if (data is List) {
          playlists.value = List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint('加载歌单失败: $e');
    }
  }

  // 更新个人资料
  Future<void> updateProfile({
    required String nickname,
    required String bio,
  }) async {
    try {
      isLoading.value = true;
      final response = await _api.put('/user/profile', data: {
        'nickname': nickname,
        'bio': bio,
      });
      if (response['code'] == 0) {
        // 更新用户信息
        await _userController.loadUserInfo();
        ToastUtil.showSuccess('资料更新成功');
      } else {
        ToastUtil.showError(response['msg'] ?? '更新失败');
      }
    } catch (e) {
      debugPrint('更新资料失败: $e');
      ToastUtil.showError('更新失败');
    } finally {
      isLoading.value = false;
    }
  }

  // 上传头像
  Future<void> uploadAvatar(String filePath) async {
    try {
      isLoading.value = true;
      final response = await _api.uploadFile(
        '/user/avatar',
        filePath,
        fieldName: 'avatar',
      );
      if (response['code'] == 0) {
        // 更新用户信息
        await _userController.loadUserInfo();
        ToastUtil.showSuccess('头像更新成功');
      } else {
        ToastUtil.showError(response['msg'] ?? '上传失败');
      }
    } catch (e) {
      debugPrint('上传头像失败: $e');
      ToastUtil.showError('上传失败');
    } finally {
      isLoading.value = false;
    }
  }

  // 退出登录
  void logout() {
    Get.defaultDialog(
      title: '退出登录',
      titleStyle: const TextStyle(color: AppTheme.textWhite),
      middleText: '确定要退出登录吗？',
      middleTextStyle: const TextStyle(color: AppTheme.textSilver),
      backgroundColor: AppTheme.surface3,
      confirm: ElevatedButton(
        onPressed: () {
          _userController.logout();
          Get.back();
          Get.offAllNamed(AppRoutes.login);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
        ),
        child: const Text('退出登录'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('取消', style: TextStyle(color: AppTheme.textSilver)),
      ),
    );
  }
}
