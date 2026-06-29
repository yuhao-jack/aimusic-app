import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/global/user_controller.dart';
import 'package:aimusic_app/modules/profile/profile_controller.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UserController _userController = UserController.to;
  final ProfileController _profileController = Get.find<ProfileController>();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    // 初始化输入框内容
    _nicknameController.text = _userController.userInfo['nickname'] ?? '';
    _bioController.text = _userController.userInfo['bio'] ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 保存修改
  Future<void> _saveChanges() async {
    final nickname = _nicknameController.text.trim();
    
    if (nickname.isEmpty) {
      ToastUtil.showWarning('昵称不能为空');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _userController.updateUserInfo(
        nickname: nickname,
      );

      if (success) {
        ToastUtil.showSuccess('保存成功');
        Get.back();
      }
    } catch (e) {
      ToastUtil.showError('保存失败');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 显示头像来源选择底部面板
  void _showAvatarSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拍照
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.textWhite),
                title: const Text('拍照', style: TextStyle(color: AppTheme.textWhite)),
                onTap: () {
                  Get.back();
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              // 从相册选择
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.textWhite),
                title: const Text('从相册选择', style: TextStyle(color: AppTheme.textWhite)),
                onTap: () {
                  Get.back();
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 选择图片并上传
  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      // 确认裁剪预览
      final confirmed = await _showAvatarPreview(File(picked.path));
      if (confirmed != true) return;

      setState(() => _isUploadingAvatar = true);
      await _profileController.uploadAvatar(picked.path);
    } catch (e) {
      ToastUtil.showError('选择图片失败');
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // 显示头像裁剪预览对话框，返回是否确认
  Future<bool?> _showAvatarPreview(File imageFile) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '头像预览',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 20),
              ClipOval(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消', style: TextStyle(color: AppTheme.textDarkGray)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                      ),
                    ),
                    child: const Text('使用此头像', style: TextStyle(color: AppTheme.textWhite)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: const Text(
          '编辑资料',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textWhite,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: Text(
              '保存',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isLoading 
                    ? AppTheme.textDarkGray 
                    : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== Avatar Section =====
            FadeInWidget(
              child: Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _showAvatarSourceSheet,
                      child: Stack(
                        children: [
                          // Gradient border effect around avatar
                          Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.secondaryColor,
                                  AppTheme.primaryColor,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 63,
                                backgroundColor: AppTheme.surface1,
                                child: Obx(() => CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppTheme.surface3,
                                  backgroundImage: _userController.userInfo['avatar'] != null
                                      ? NetworkImage(_userController.userInfo['avatar'])
                                      : null,
                                  child: _userController.userInfo['avatar'] == null
                                      ? const Icon(
                                          Icons.person_outline,
                                          size: 48,
                                          color: AppTheme.textDarkGray,
                                        )
                                      : null,
                                )),
                              ),
                            ),
                          ),
                          // Edit Button
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.surface1,
                                  width: 3,
                                ),
                              ),
                              child: _isUploadingAvatar
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textWhite),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 20,
                                      color: AppTheme.textWhite,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isUploadingAvatar ? null : _showAvatarSourceSheet,
                      child: Text(
                        _isUploadingAvatar ? '上传中...' : '更换头像',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isUploadingAvatar
                              ? AppTheme.textDarkGray
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ===== Nickname Field =====
            FadeInWidget(
              delayMs: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('昵称'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nicknameController,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                    ),
                    decoration: InputDecoration(
                      hintText: '请输入昵称',
                      hintStyle: const TextStyle(
                        color: AppTheme.textDarkGray,
                      ),
                      filled: true,
                      fillColor: AppTheme.surface3,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ===== Bio Field =====
            FadeInWidget(
              delayMs: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('个人简介'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                    ),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: '介绍一下自己吧...',
                      hintStyle: const TextStyle(
                        color: AppTheme.textDarkGray,
                      ),
                      filled: true,
                      fillColor: AppTheme.surface3,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ===== Save Button =====
            FadeInWidget(
              delayMs: 180,
              child: SizedBox(
                height: 56,
                child: ElasticButton(
                  onTap: _isLoading ? null : _saveChanges,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _isLoading ? null : AppTheme.primaryToSecondary,
                      color: _isLoading ? AppTheme.surface3 : null,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textWhite),
                              ),
                            )
                          : const Text(
                              '保存修改',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textWhite,
                                letterSpacing: 1.6,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSilver,
      ),
    );
  }
}
