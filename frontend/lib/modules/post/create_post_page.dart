import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'create_post_controller.dart';

class CreatePostPage extends GetView<CreatePostController> {
  CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Text(
          '发布动态',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.close_rounded, color: AppTheme.textWhite, size: 24),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Obx(() {
              final isBusy = controller.isLoading.value || controller.isUploading.value;
              return GestureDetector(
                onTap: isBusy ? null : () => controller.publishPost(),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isBusy
                        ? AppTheme.brandIndigo.withValues(alpha: 0.3)
                        : AppTheme.brandIndigo,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  ),
                  child: isBusy
                      ? SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            color: AppTheme.textWhite, strokeWidth: 2,
                          ),
                        )
                      : Text('发布', style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                ),
              );
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 内容输入区
            _buildContentInput(),
            SizedBox(height: 12),
            // 话题推荐
            _buildTopicSection(),
            SizedBox(height: 20),
            // 图片预览区
            _buildImageSection(),
            SizedBox(height: 20),
            // 上传进度
            Obx(() {
              if (!controller.isUploading.value) return SizedBox.shrink();
              return _buildUploadProgress();
            }),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ===== 内容输入 =====
  Widget _buildContentInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.borderSubtle.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller.contentController,
            decoration: InputDecoration(
              hintText: '分享你的音乐想法...（用 #话题# 插入话题）',
              hintStyle: TextStyle(color: AppTheme.textDarkGray.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: 8,
            minLines: 4,
            maxLength: 500,
            textInputAction: TextInputAction.newline,
            autofocus: true,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppTheme.textWhite,
            ),
            buildCounter: (context, {required currentLength, required isFocused, required maxLength}) {
              return Padding(
                padding: EdgeInsets.only(right: 16, bottom: 8),
                child: Text(
                  '$currentLength/$maxLength',
                  style: TextStyle(
                    fontSize: 12,
                    color: currentLength > (maxLength ?? 500) * 0.9
                        ? AppTheme.warningColor
                        : AppTheme.textDarkGray,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===== 话题推荐区 =====
  Widget _buildTopicSection() {
    return Obx(() {
      final topics = controller.recommendTopics;
      if (topics.isEmpty) return SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag_rounded, size: 16, color: AppTheme.brandIndigo),
              SizedBox(width: 6),
              Text('热门话题', style: TextStyle(
                fontSize: 13, color: AppTheme.textSilver,
              )),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topics.map((topic) {
              final isSelected = controller.selectedTopics.contains(topic);
              return GestureDetector(
                onTap: () => controller.insertTopic(topic),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.brandIndigo.withValues(alpha: 0.2)
                        : AppTheme.surface3.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.brandIndigo.withValues(alpha: 0.5)
                          : AppTheme.borderSubtle.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text('#$topic#', style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? AppTheme.brandIndigo : AppTheme.textSilver,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }

  // ===== 图片区域 =====
  Widget _buildImageSection() {
    return Obx(() {
      final localCount = controller.localImages.length;
      final uploadedCount = controller.uploadedUrls.length;
      final totalCount = localCount + uploadedCount;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Text('图片', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
              )),
              SizedBox(width: 8),
              if (totalCount > 0)
                Text('$totalCount/9', style: TextStyle(
                  fontSize: 13, color: AppTheme.textLightGray,
                )),
            ],
          ),
          SizedBox(height: 12),
          // 图片网格
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // 已上传的图片
              ...List.generate(uploadedCount, (i) => _buildUploadedItem(i)),
              // 本地待上传的图片
              ...List.generate(localCount, (i) => _buildLocalItem(i)),
              // 添加按钮
              if (totalCount < 9) _buildAddButton(),
            ],
          ),
        ],
      );
    });
  }

  // ===== 已上传图片项 =====
  Widget _buildUploadedItem(int index) {
    final url = controller.uploadedUrls[index];
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showFullImage(url, isLocal: false),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              width: 100, height: 100, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100, height: 100, color: AppTheme.surface2,
                child: Icon(Icons.broken_image, color: AppTheme.textDarkGray),
              ),
            ),
          ),
        ),
        // 已上传标记
        Positioned(
          bottom: 4, left: 4,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('已上传', style: TextStyle(
              fontSize: 9, color: AppTheme.textWhite, fontWeight: FontWeight.w600,
            )),
          ),
        ),
        // 删除按钮
        _buildDeleteBtn(() => controller.removeUploadedUrl(index)),
      ],
    );
  }

  // ===== 本地图片项 =====
  Widget _buildLocalItem(int index) {
    final file = controller.localImages[index];
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showFullImage(file.path, isLocal: true),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(file.path),
              width: 100, height: 100, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100, height: 100, color: AppTheme.surface2,
                child: Icon(Icons.broken_image, color: AppTheme.textDarkGray),
              ),
            ),
          ),
        ),
        // 待上传标记
        Positioned(
          bottom: 4, left: 4,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.brandIndigo.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('待上传', style: TextStyle(
              fontSize: 9, color: AppTheme.textWhite, fontWeight: FontWeight.w600,
            )),
          ),
        ),
        // 删除按钮
        _buildDeleteBtn(() => controller.removeLocalImage(index)),
      ],
    );
  }

  // ===== 查看大图 =====
  void _showFullImage(String path, {required bool isLocal}) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Get.back(),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isLocal
                  ? Image.file(File(path), fit: BoxFit.contain)
                  : Image.network(path, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  // ===== 删除按钮 =====
  Widget _buildDeleteBtn(VoidCallback onTap) {
    return Positioned(
      top: 4, right: 4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close_rounded, size: 14, color: AppTheme.textWhite),
        ),
      ),
    );
  }

  // ===== 添加按钮 =====
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(),
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: AppTheme.surface3.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.borderSubtle.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 32, color: AppTheme.textLightGray.withValues(alpha: 0.6)),
            SizedBox(height: 4),
            Text('添加', style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLightGray.withValues(alpha: 0.6),
            )),
          ],
        ),
      ),
    );
  }

  // ===== 图片来源选择 =====
  void _showImageSourceSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text('选择图片来源', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
              )),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: '相册（多选）',
                    onTap: () {
                      Get.back();
                      controller.pickImages();
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: '拍照',
                    onTap: () {
                      Get.back();
                      controller.takePhoto();
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppTheme.brandIndigo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: AppTheme.brandIndigo),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(
            fontSize: 13, color: AppTheme.textSilver,
          )),
        ],
      ),
    );
  }

  // ===== 上传进度 =====
  Widget _buildUploadProgress() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.cloud_upload_rounded, size: 20, color: AppTheme.brandIndigo),
              SizedBox(width: 10),
              Text('正在上传图片...', style: TextStyle(
                fontSize: 14, color: AppTheme.textWhite,
              )),
              Spacer(),
              Text(
                '${controller.uploadProgress.value}/${controller.localImages.length}',
                style: TextStyle(fontSize: 13, color: AppTheme.textSilver),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: controller.localImages.isNotEmpty
                  ? controller.uploadProgress.value / controller.localImages.length
                  : 0,
              backgroundColor: AppTheme.surface2,
              valueColor: AlwaysStoppedAnimation(AppTheme.brandIndigo),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
