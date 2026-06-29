import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/utils/storage_util.dart';
import 'package:aimusic_app/routes/app_routes.dart';

/// 引导页控制器 — 管理引导流程状态和用户偏好保存
class OnboardingController extends GetxController {
  /// 当前页码
  final currentPage = 0.obs;

  /// 用户选择的音乐风格
  final selectedGenres = <String>[].obs;

  /// 用户选择的心情偏好
  final selectedMoods = <String>[].obs;

  /// 可选音乐风格列表
  static const List<Map<String, dynamic>> genres = [
    {'label': '流行', 'icon': '🎵'},
    {'label': '民谣', 'icon': '🎸'},
    {'label': '摇滚', 'icon': '🤘'},
    {'label': '电子', 'icon': '🎧'},
    {'label': '说唱', 'icon': '🎤'},
    {'label': '古典', 'icon': '🎻'},
    {'label': 'R&B', 'icon': '🎶'},
    {'label': '爵士', 'icon': '🎷'},
  ];

  /// 可选心情列表
  static const List<Map<String, dynamic>> moods = [
    {'label': '开心', 'icon': '😊'},
    {'label': '伤感', 'icon': '😢'},
    {'label': '平静', 'icon': '😌'},
    {'label': '热血', 'icon': '🔥'},
    {'label': '浪漫', 'icon': '💕'},
    {'label': '孤独', 'icon': '🌙'},
  ];

  /// 切换风格选择
  void toggleGenre(String genre) {
    if (selectedGenres.contains(genre)) {
      selectedGenres.remove(genre);
    } else {
      selectedGenres.add(genre);
    }
  }

  /// 切换心情选择
  void toggleMood(String mood) {
    if (selectedMoods.contains(mood)) {
      selectedMoods.remove(mood);
    } else {
      selectedMoods.add(mood);
    }
  }

  /// 完成引导，保存偏好并跳转
  Future<void> completeOnboarding() async {
    try {
      // 保存偏好到本地存储
      await StorageUtil.setBool('onboarding_completed', true);
      await StorageUtil.setJson('user_preferences', {
        'genres': selectedGenres.toList(),
        'moods': selectedMoods.toList(),
      });
      debugPrint('引导完成，偏好已保存: genres=$selectedGenres, moods=$selectedMoods');

      // 跳转到登录页
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      debugPrint('保存引导偏好失败: $e');
      Get.offAllNamed(AppRoutes.login);
    }
  }

  /// 检查是否已完成引导
  static bool isOnboardingCompleted() {
    return StorageUtil.getBool('onboarding_completed') ?? false;
  }

  /// 获取保存的用户偏好
  static Map<String, dynamic>? getUserPreferences() {
    return StorageUtil.getJson('user_preferences');
  }
}
