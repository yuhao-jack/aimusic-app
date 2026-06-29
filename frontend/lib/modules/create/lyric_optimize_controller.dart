import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/utils/http_util.dart';
import 'package:aimusic_app/utils/toast_util.dart';

class LyricOptimizeController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool hasOptimized = false.obs;
  final RxString originalLyric = ''.obs;
  final RxString optimizedLyric = ''.obs;
  final RxString selectedStyle = '流行'.obs;

  final List<String> styles = ['流行', '说唱', '民谣', '摇滚', '电子', 'R&B', '国风'];

  Future<void> optimizeLyric() async {
    if (originalLyric.value.trim().isEmpty) {
      ToastUtil.showWarning('请输入要优化的歌词');
      return;
    }

    isLoading.value = true;
    try {
      final response = await HttpUtil().post(
        '/ai/optimize-lyric',
        data: {
          'lyric': originalLyric.value,
          'style': selectedStyle.value,
        },
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final data = response.data['data'];
        optimizedLyric.value = data['optimized_lyric'] ?? '';
        hasOptimized.value = true;
        ToastUtil.showSuccess('优化成功！');
      } else {
        debugPrint(response.data['message'] ?? '优化失败');
      }
    } catch (e) {
      debugPrint('优化失败，请重试');
    } finally {
      isLoading.value = false;
    }
  }
}
