import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

class MyLikesController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final RxList likes = [].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadLikes();
  }

  Future<void> loadLikes() async {
    isLoading.value = true;
    try {
      final response = await api.get('/user/likes');
      if (response['code'] == 0) {
        final data = response['data'];
        if (data is List) {
          likes.value = data;
        } else if (data is Map && data['list'] is List) {
          likes.value = data['list'];
        }
      }
    } catch (e) {
      debugPrint('加载喜欢列表失败：$e');
    } finally {
      isLoading.value = false;
    }
  }
}
