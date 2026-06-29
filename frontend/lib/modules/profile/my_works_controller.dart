import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

class MyWorksController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final RxList works = [].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadWorks();
  }

  Future<void> loadWorks() async {
    isLoading.value = true;
    try {
      final response = await api.get('/user/works');
      if (response['code'] == 0) {
        final data = response['data'];
        if (data is List) {
          works.value = data;
        } else if (data is Map && data['list'] is List) {
          works.value = data['list'];
        }
      }
    } catch (e) {
      debugPrint('加载作品失败：$e');
    } finally {
      isLoading.value = false;
    }
  }
}
