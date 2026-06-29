import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

class VoiceCloneController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final RxList voices = [].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadVoices();
  }

  Future<void> loadVoices() async {
    isLoading.value = true;
    try {
      final response = await api.get('/voice/clones');
      if (response['code'] == 0) {
        voices.value = response['data']['list'] ?? [];
      }
    } catch (e) {
      debugPrint('加载音色列表失败：$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> createVoiceClone({
    required String name,
    String description = '',
    required String audioUrl,
  }) async {
    try {
      final response = await api.post('/voice/clones', data: {
        'name': name,
        'description': description,
        'audio_url': audioUrl,
      });
      if (response['code'] == 0) {
        await loadVoices();
        return response['data'];
      }
    } catch (e) {
      debugPrint('创建音色失败：$e');
    }
    return null;
  }

  Future<void> updateVoiceClone(int id, {String? name, String? description}) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      
      final response = await api.put('/voice/clones/$id', data: data);
      if (response['code'] == 0) {
        await loadVoices();
      }
    } catch (e) {
      debugPrint('更新音色失败：$e');
    }
  }

  Future<void> deleteVoiceClone(int id) async {
    try {
      final response = await api.delete('/voice/clones/$id');
      if (response['code'] == 0) {
        voices.removeWhere((v) => v['id'] == id);
      }
    } catch (e) {
      debugPrint('删除音色失败：$e');
    }
  }
}
