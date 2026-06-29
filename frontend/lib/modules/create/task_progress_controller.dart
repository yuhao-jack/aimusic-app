import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/routes/app_routes.dart';

class TaskProgressController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final RxBool isLoading = true.obs;
  final RxString status = "".obs;
  final RxString progress = "".obs;
  final RxInt progressPercent = 0.obs;
  final RxMap<String, dynamic> result = <String, dynamic>{}.obs;
  late String taskId;

  @override
  void onInit() {
    super.onInit();
    taskId = Get.arguments is String ? Get.arguments : '';
    pollProgress();
  }

  void pollProgress() {
    if (taskId.isEmpty) return;

    _fetchProgress();

    if (status.value != "completed" && status.value != "success" && status.value != "failed") {
      Future.delayed(const Duration(seconds: 3), () {
        pollProgress();
      });
    }
  }

  Future<void> _fetchProgress() async {
    isLoading.value = true;
    try {
      final response = await api.get('/ai/task/$taskId/progress');
      if (response['code'] == 0) {
        final data = response['data'];
        status.value = data['status'] ?? "pending";
        progress.value = data['progress_msg'] ?? data['progress'] ?? "";
        progressPercent.value = data['progress'] is int ? data['progress'] : 0;
        
        // 如果有结果数据，保存下来
        if (data['result'] != null) {
          result.value = data['result'] is Map ? Map<String, dynamic>.from(data['result']) : {};
        }
      }
    } catch (e) {
      debugPrint('获取任务进度失败: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // 跳转到音乐详情页
  void goToMusicDetail() {
    final musicId = result['music_id'] ?? result['song_id'];
    if (musicId != null) {
      Get.offNamed(AppRoutes.musicDetail, arguments: musicId);
    } else {
      Get.back();
    }
  }
}
