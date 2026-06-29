import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CreateController extends GetxController {
  final RxList _works = [].obs;
  List get works => _works;

  /// MV生成弹窗 - 选中的歌曲索引
  final Rx<int?> mvSelectedSong = Rx<int?>(null);
  /// MV生成弹窗 - 选中的MV风格
  final RxString mvSelectedStyle = '科幻'.obs;
  /// MV生成弹窗 - 已选择的素材文件（图片/视频）
  final RxList<XFile> mvMediaFiles = <XFile>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadMyWorks();
  }

  Future<void> _loadMyWorks() async {
    // 加载用户作品列表，后续对接接口
    _works.value = [];
  }

  /// 下拉刷新 - 重新加载最近创作列表
  Future<void> refreshWorks() async {
    await _loadMyWorks();
  }

  /// 选择MV素材（图片+视频混合选择）
  Future<void> pickMvMedia() async {
    final picker = ImagePicker();
    try {
      // 先选图片（支持多选）
      final images = await picker.pickMultiImage(imageQuality: 80);
      if (images.isNotEmpty) {
        mvMediaFiles.addAll(images);
      }
      // 再选一个视频
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        mvMediaFiles.add(video);
      }
    } catch (e) {
      debugPrint('选择MV素材失败: $e');
    }
  }

  /// 移除已选素材
  void removeMvMedia(int index) {
    if (index >= 0 && index < mvMediaFiles.length) {
      mvMediaFiles.removeAt(index);
    }
  }

  /// 清空已选素材
  void clearMvMedia() {
    mvMediaFiles.clear();
  }
}
