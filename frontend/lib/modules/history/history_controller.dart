import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

class HistoryController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final RxList histories = [].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistories();
  }

  Future<void> loadHistories() async {
    isLoading.value = true;
    try {
      final response = await api.get('/history');
      if (response['code'] == 0) {
        histories.value = response['data']['list'] ?? [];
      }
    } catch (e) {
      debugPrint('加载历史记录失败：$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeHistory(int id) async {
    try {
      final response = await api.delete('/history/$id');
      if (response['code'] == 0) {
        histories.removeWhere((h) => h['id'] == id);
      }
    } catch (e) {
      debugPrint('删除历史记录失败：$e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final response = await api.delete('/history');
      if (response['code'] == 0) {
        histories.clear();
      }
    } catch (e) {
      debugPrint('清空历史记录失败：$e');
    }
  }

  /// 添加播放历史记录
  Future<void> addHistory(int songId) async {
    try {
      await api.post('/history', data: {'song_id': songId});
    } catch (e) {
      // 静默失败，不影响播放体验
    }
  }
}
