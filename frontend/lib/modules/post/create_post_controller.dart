import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/utils/toast_util.dart';

class CreatePostController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final ImagePicker _picker = ImagePicker();

  final contentController = TextEditingController();

  /// 本地图片路径
  final RxList<XFile> localImages = <XFile>[].obs;

  /// 已上传的图片URL
  final RxList<String> uploadedUrls = <String>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxInt uploadProgress = 0.obs;

  /// 推荐话题列表
  final RxList<String> recommendTopics = <String>[].obs;

  /// 从内容中提取的话题标签
  final RxList<String> selectedTopics = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadRecommendTopics();
    contentController.addListener(_extractTopics);
  }

  /// 从API加载推荐话题
  Future<void> _loadRecommendTopics() async {
    try {
      final response = await api.get('/post/topics');
      if (response != null && response['code'] == 0) {
        final data = response['data'];
        if (data is List) {
          recommendTopics.value = data.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('加载推荐话题失败: $e');
      recommendTopics.value = ['AI音乐', '原创', '翻唱', '民谣', '电子', '说唱'];
    }
  }

  /// 从输入内容中提取话题标签
  void _extractTopics() {
    final text = contentController.text;
    final regex = RegExp(r'#([^#]+)#');
    final matches = regex.allMatches(text);
    selectedTopics.value = matches.map((m) => m.group(1)!).toList();
  }

  /// 在光标位置插入话题
  void insertTopic(String topic) {
    final text = contentController.text;
    final selection = contentController.selection;
    final insert = '#$topic#';
    final newText = text.replaceRange(selection.start, selection.end, insert);
    contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + insert.length),
    );
  }

  /// 从相册选择多张图片
  Future<void> pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
      );
      if (picked.isEmpty) return;

      final remaining = 9 - localImages.length;
      if (remaining <= 0) {
        ToastUtil.warning('最多只能选择9张图片');
        return;
      }

      final toAdd = picked.take(remaining).toList();
      localImages.addAll(toAdd);

      if (picked.length > remaining) {
        ToastUtil.warning('已选择${toAdd.length}张，超出部分已忽略');
      }
    } catch (e) {
      ToastUtil.showError('选择图片失败');
    }
  }

  /// 从相机拍照
  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
      );
      if (photo == null) return;

      if (localImages.length >= 9) {
        ToastUtil.warning('最多只能选择9张图片');
        return;
      }

      localImages.add(photo);
    } catch (e) {
      ToastUtil.showError('拍照失败');
    }
  }

  /// 移除本地图片
  void removeLocalImage(int index) {
    if (index >= 0 && index < localImages.length) {
      localImages.removeAt(index);
    }
  }

  /// 移除已上传图片
  void removeUploadedUrl(int index) {
    if (index >= 0 && index < uploadedUrls.length) {
      uploadedUrls.removeAt(index);
    }
  }

  /// 上传单张图片
  Future<String?> _uploadSingleImage(XFile file) async {
    try {
      final response = await api.uploadFile('/upload', file.path, fieldName: 'file');
      if (response != null && response['code'] == 0) {
        return response?['data']?['url'] as String?;
      }
    } catch (e) {
      debugPrint('上传图片失败: $e');
    }
    return null;
  }

  /// 发布动态
  Future<void> publishPost() async {
    if (isLoading.value) return;

    final content = contentController.text.trim();
    final hasImages = localImages.isNotEmpty || uploadedUrls.isNotEmpty;

    if (content.isEmpty && !hasImages) {
      ToastUtil.warning('请输入内容或添加图片');
      return;
    }

    isLoading.value = true;
    ToastUtil.info('正在发布...');

    try {
      // 上传本地图片
      if (localImages.isNotEmpty) {
        isUploading.value = true;
        for (int i = 0; i < localImages.length; i++) {
          final url = await _uploadSingleImage(localImages[i]);
          if (url != null) uploadedUrls.add(url);
          uploadProgress.value = i + 1;
        }
        isUploading.value = false;
        localImages.clear();
      }

      // 构建请求
      final data = <String, dynamic>{'content': content};
      if (uploadedUrls.isNotEmpty) data['images'] = uploadedUrls.toList();

      // 调用API
      final response = await api.post('/post/create', data: data);
      
      if (response['code'] == 0) {
        ToastUtil.showSuccess('发布成功');
        contentController.clear();
        uploadedUrls.clear();
        selectedTopics.clear();
        Get.back(result: true);
      } else {
        ToastUtil.showError(response['msg'] ?? response['message'] ?? '发布失败');
      }
    } catch (e) {
      debugPrint('发布失败详情: $e');
      ToastUtil.showError('网络错误，请重试');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    contentController.dispose();
    super.onClose();
  }
}
