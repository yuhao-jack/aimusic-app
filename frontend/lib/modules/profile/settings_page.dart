import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/profile/settings_controller.dart';
import 'package:aimusic_app/modules/profile/edit_profile_page.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/theme/theme_provider.dart';
import 'package:aimusic_app/theme/theme_config.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textWhite,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: StaggeredList(
          startDelay: 0,
          staggerDelay: 100,
          children: [
            // ===== Account Section =====
            _buildSection(
              title: '账号',
              items: [
                _buildSettingItem(
                  icon: Icons.person_outline,
                  title: '个人资料',
                  subtitle: '编辑你的昵称和简介',
                  onTap: () => Get.to(() => const EditProfilePage()),
                ),
                _buildSettingItem(
                  icon: Icons.lock_outline,
                  title: '修改密码',
                  subtitle: '更新你的登录密码',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                _buildSettingItem(
                  icon: Icons.phone_outlined,
                  title: '绑定手机',
                  subtitle: '绑定手机号码',
                  onTap: () => _showBindPhoneDialog(context),
                ),
              ],
            ),

            // ===== Preferences Section =====
            _buildSection(
              title: '偏好设置',
              items: [
                Obx(() => _buildSwitchItem(
                      icon: Icons.dark_mode_outlined,
                      title: '深色模式',
                      subtitle: '使用深色主题',
                      value: controller.darkMode.value,
                      onChanged: (value) => controller.updateDarkMode(value),
                    )),
                Obx(() => _buildSwitchItem(
                      icon: Icons.notifications_outlined,
                      title: '推送通知',
                      subtitle: '接收新消息提醒',
                      value: controller.notifications.value,
                      onChanged: (value) =>
                          controller.updateNotifications(value),
                    )),
                _buildSettingItem(
                  icon: Icons.language_outlined,
                  title: '语言',
                  subtitle: '简体中文',
                  onTap: () => _showLanguageDialog(context),
                ),
              ],
            ),

            // ===== Theme Section =====
            Obx(() => _buildThemeSection()),

            // ===== Audio Section =====
            _buildSection(
              title: '音频设置',
              items: [
                _buildSettingItem(
                  icon: Icons.volume_up_outlined,
                  title: '音质选择',
                  subtitle: '标准',
                  onTap: () => _showAudioQualitySheet(context),
                ),
                Obx(() => _buildSwitchItem(
                      icon: Icons.headphones_outlined,
                      title: '仅WiFi下载',
                      subtitle: '节省移动数据流量',
                      value: controller.wifiOnlyDownload.value,
                      onChanged: (value) =>
                          controller.updateWifiOnlyDownload(value),
                    )),
                Obx(() => _buildSwitchItem(
                      icon: Icons.play_circle_outline,
                      title: '自动播放',
                      subtitle: '自动播放下一首',
                      value: controller.autoPlay.value,
                      onChanged: (value) => controller.updateAutoPlay(value),
                    )),
              ],
            ),

            // ===== My Content Section =====
            _buildSection(
              title: '我的内容',
              items: [
                _buildSettingItem(
                  icon: Icons.queue_music_rounded,
                  title: '我的作品',
                  subtitle: '查看你创作的所有作品',
                  onTap: () => Get.toNamed(AppRoutes.myWorks),
                ),
                _buildSettingItem(
                  icon: Icons.favorite_rounded,
                  title: '我的喜欢',
                  subtitle: '查看你喜欢的歌曲',
                  onTap: () => Get.toNamed(AppRoutes.myLikes),
                ),
                _buildSettingItem(
                  icon: Icons.history_rounded,
                  title: '播放历史',
                  subtitle: '查看你的播放记录',
                  onTap: () => Get.toNamed(AppRoutes.history),
                ),
                _buildSettingItem(
                  icon: Icons.bar_chart_rounded,
                  title: '听歌报告',
                  subtitle: '查看本周听歌数据统计',
                  onTap: () => Get.toNamed(AppRoutes.listeningReport),
                ),
              ],
            ),

            // ===== About Section =====
            _buildSection(
              title: '关于',
              items: [
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: '关于我们',
                  subtitle: '了解更多信息',
                  onTap: () => _showAboutDialog(context),
                ),
                _buildSettingItem(
                  icon: Icons.help_outline,
                  title: '帮助与反馈',
                  subtitle: '常见问题和意见反馈',
                  onTap: () => _showHelpDialog(context),
                ),
                _buildSettingItem(
                  icon: Icons.privacy_tip_outlined,
                  title: '隐私政策',
                  subtitle: '查看隐私政策',
                  onTap: () => _showPrivacyPolicyDialog(context),
                ),
                _buildSettingItem(
                  icon: Icons.description_outlined,
                  title: '用户协议',
                  subtitle: '查看用户协议',
                  onTap: () => _showUserAgreementDialog(context),
                ),
              ],
            ),

            // ===== Logout Button =====
            const SizedBox(height: AppTheme.spaceLg),
            FadeInWidget(
              delayMs: 800,
              child: Center(
                child: SizedBox(
                  height: 56,
                  child: _buildLogoutButton(),
                ),
              ),
            ),

            // ===== Version Info =====
            const SizedBox(height: AppTheme.space2Xl),
            FadeInWidget(
              delayMs: 900,
              child: Center(
                child: Text(
                  '版本 1.0.0',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDarkGray,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 渐变红色边框的退出登录按钮
  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFEF4444),
            Color(0xFFB91C1C),
            Color(0xFFEF4444),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.logout,
            splashColor: AppTheme.errorColor.withOpacity(0.15),
            highlightColor: AppTheme.errorColor.withOpacity(0.08),
            child: Container(
              width: double.infinity,
              height: 52,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              ),
              alignment: Alignment.center,
              child: const Text(
                '退出登录',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== Theme Section =====
  Widget _buildThemeSection() {
    final themes = ThemeProvider.to.themes;
    final currentIndex = ThemeProvider.to.currentIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spaceXs,
            bottom: AppTheme.spaceSm,
          ),
          child: Text(
            '主题',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDeepGray,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: themes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final theme = themes[index];
                final isSelected = index == currentIndex;
                return _buildThemeCard(theme, index, isSelected);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 单个主题卡片
  Widget _buildThemeCard(ThemeConfig theme, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => ThemeProvider.to.selectTheme(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 80,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: isSelected ? theme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 色环预览
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  theme.icon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              theme.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? theme.primary : AppTheme.textLightGray,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===== Section Widget =====
  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spaceXs,
            bottom: AppTheme.spaceSm,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDeepGray,
            ),
          ),
        ),
        // Section Card Container
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (context, index) => Container(
              height: 0.5,
              color: AppTheme.borderSubtle,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }

  // ===== Setting Item Widget =====
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                icon,
                size: 22,
                color: AppTheme.textSilver,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLightGray,
                    ),
                  ),
                ],
              ),
            ),
            // Right Arrow
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.textDarkGray,
            ),
          ],
        ),
      ),
    );
  }

  // ===== Switch Item Widget =====
  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppTheme.textSilver,
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLightGray,
                  ),
                ),
              ],
            ),
          ),
          // Switch
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
            inactiveThumbColor: AppTheme.textMediumGray,
            inactiveTrackColor: AppTheme.surface2,
          ),
        ],
      ),
    );
  }

  // ===== 通用对话框样式 =====

  /// 构建统一风格的对话框
  Widget _buildDialog({
    required String title,
    required Widget child,
    List<Widget>? actions,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceLg),
            // 内容
            child,
            // 按钮区域
            if (actions != null) ...[
              const SizedBox(height: AppTheme.spaceXl),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }

  /// 构建对话框底部按钮
  Widget _buildDialogButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.primaryColor : Colors.transparent,
        foregroundColor: AppTheme.textWhite,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: AppTheme.borderGray),
        ),
      ),
      child: Text(text),
    );
  }

  // ===== 修改密码对话框 =====
  void _showChangePasswordDialog(BuildContext context) {
    final oldPwdController = TextEditingController();
    final newPwdController = TextEditingController();
    final confirmPwdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        title: '修改密码',
        child: Column(
          children: [
            _buildTextField(controller: oldPwdController, hint: '请输入旧密码'),
            const SizedBox(height: AppTheme.spaceMd),
            _buildTextField(controller: newPwdController, hint: '请输入新密码'),
            const SizedBox(height: AppTheme.spaceMd),
            _buildTextField(controller: confirmPwdController, hint: '请确认新密码'),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: _buildDialogButton(
                  text: '取消',
                  isPrimary: false,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDialogButton(
                  text: '确认修改',
                  onPressed: () async {
                    final oldPwd = oldPwdController.text.trim();
                    final newPwd = newPwdController.text.trim();
                    final confirmPwd = confirmPwdController.text.trim();
                    if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
                      ToastUtil.warning('请填写所有密码字段');
                      return;
                    }
                    if (newPwd.length < 6) {
                      ToastUtil.warning('新密码长度不能少于6位');
                      return;
                    }
                    if (newPwd != confirmPwd) {
                      ToastUtil.warning('两次输入的新密码不一致');
                      return;
                    }
                    Navigator.of(ctx).pop();
                    // 调用修改密码
                    await controller.changePassword(newPwd);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== 绑定手机对话框 =====
  void _showBindPhoneDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final codeController = TextEditingController();
    // 重置倒计时
    controller.phoneCountdown.value = 0;
    Timer? timer;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return _buildDialog(
            title: '绑定手机号',
            child: Column(
              children: [
                // 手机号输入框
                _buildTextField(
                  controller: phoneController,
                  hint: '请输入手机号',
                  obscureText: false,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppTheme.spaceMd),
                // 验证码输入框 + 获取验证码按钮
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: codeController,
                        hint: '请输入验证码',
                        obscureText: false,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        onPressed: controller.phoneCountdown.value > 0
                            ? null
                            : () {
                                final phone = phoneController.text.trim();
                                if (phone.isEmpty) {
                                  ToastUtil.warning('请先输入手机号');
                                  return;
                                }
                                if (phone.length != 11) {
                                  ToastUtil.warning('请输入正确的手机号');
                                  return;
                                }
                                // 模拟发送验证码
                                ToastUtil.showSuccess('验证码已发送');
                                // 开始60秒倒计时
                                controller.phoneCountdown.value = 60;
                                timer?.cancel();
                                timer = Timer.periodic(
                                  const Duration(seconds: 1),
                                  (t) {
                                    if (controller.phoneCountdown.value <= 0) {
                                      t.cancel();
                                    } else {
                                      controller.phoneCountdown.value--;
                                    }
                                  },
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                          ),
                        ),
                        child: Obx(() => Text(
                          controller.phoneCountdown.value > 0 ? '${controller.phoneCountdown.value}s' : '获取验证码',
                          style: const TextStyle(fontSize: 14),
                        )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: _buildDialogButton(
                      text: '取消',
                      isPrimary: false,
                      onPressed: () {
                        timer?.cancel();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDialogButton(
                      text: '绑定',
                      onPressed: () {
                        final phone = phoneController.text.trim();
                        final code = codeController.text.trim();
                        if (phone.isEmpty) {
                          ToastUtil.warning('请输入手机号');
                          return;
                        }
                        if (phone.length != 11) {
                          ToastUtil.warning('请输入正确的手机号');
                          return;
                        }
                        if (code.isEmpty) {
                          ToastUtil.warning('请输入验证码');
                          return;
                        }
                        if (code.length != 6) {
                          ToastUtil.warning('验证码为6位数字');
                          return;
                        }
                        timer?.cancel();
                        Navigator.of(ctx).pop();
                        // 模拟绑定成功
                        ToastUtil.success('手机号绑定成功');
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ).then((_) {
      timer?.cancel();
    });
  }

  /// 构建统一风格的输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textWhite),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textDarkGray),
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: const BorderSide(color: AppTheme.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: const BorderSide(color: AppTheme.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  // ===== 语言选择对话框 =====
  void _showLanguageDialog(BuildContext context) {
    // 读取当前语言设置
    final isZh = Get.locale?.languageCode == 'zh';
    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        title: '选择语言',
        child: Column(
          children: [
            _buildLanguageOption(ctx, '简体中文', isZh, const Locale('zh', 'CN')),
            const Divider(color: AppTheme.borderSubtle, height: 1),
            _buildLanguageOption(ctx, 'English', !isZh, const Locale('en', 'US')),
          ],
        ),
      ),
    );
  }

  /// 构建语言选项行
  Widget _buildLanguageOption(
      BuildContext ctx, String language, bool isSelected, Locale locale) {
    return InkWell(
      onTap: () async {
        Navigator.of(ctx).pop();
        // 保存语言偏好到本地存储
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('locale', locale.languageCode);
        // 切换语言
        Get.updateLocale(locale);
        ToastUtil.success('语言已切换');
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textWhite,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, size: 20, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  // ===== 音质选择底部弹出 =====
  void _showAudioQualitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示条
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textDarkGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题
            const Padding(
              padding: EdgeInsets.all(AppTheme.spaceXl),
              child: Text(
                '音质选择',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
            // 选项列表
            _buildQualityOption(ctx, '标准', '128kbps · 节省流量', true),
            _buildQualityOption(ctx, '高品质', '328kbps · 推荐', false),
            _buildQualityOption(ctx, '无损', 'FLAC · HiFi体验', false),
            const SizedBox(height: AppTheme.spaceXl),
          ],
        ),
      ),
    );
  }

  /// 构建音质选项行
  Widget _buildQualityOption(
    BuildContext ctx,
    String title,
    String subtitle,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(ctx).pop();
        ToastUtil.success('音质设置已保存');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLightGray,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, size: 20, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  // ===== 关于我们对话框 =====
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        title: '关于我们',
        child: Column(
          children: [
            // 应用图标
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryToSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: const Icon(Icons.music_note_rounded, size: 32, color: AppTheme.textWhite),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            const Text(
              '音浪AI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '版本 v1.0.0',
              style: TextStyle(fontSize: 14, color: AppTheme.textLightGray),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            const Text(
              'AI 音乐创作平台，让每个人都能轻松创作音乐。',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSilver,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            const Text(
              '© 2024 音浪AI 版权所有',
              style: TextStyle(fontSize: 12, color: AppTheme.textDarkGray),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: _buildDialogButton(
              text: '确定',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 帮助与反馈对话框 =====
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        title: '帮助与反馈',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFaqItem('如何创作音乐？',
                '在首页点击"AI创作"，输入歌词或选择风格，AI将自动生成音乐。'),
            _buildFaqItem('如何下载歌曲？',
                '在歌曲详情页点击下载按钮，支持离线播放。'),
            _buildFaqItem('如何联系客服？',
                '发送邮件至 support@aimusic.com，我们将在24小时内回复。'),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: _buildDialogButton(
              text: '我知道了',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建FAQ条目
  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q: $question',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A: $answer',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSilver,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===== 隐私政策对话框 =====
  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        title: '隐私政策',
        child: const SingleChildScrollView(
          child: Text(
            '我们非常重视您的隐私保护。本隐私政策说明我们如何收集、使用和保护您的个人信息。\n\n'
            '1. 信息收集：我们仅收集提供服务所必需的信息，包括账号信息和使用数据。\n\n'
            '2. 信息使用：您的信息仅用于提供和改进服务，不会用于其他商业目的。\n\n'
            '3. 信息保护：我们采用行业标准的加密技术保护您的数据安全。\n\n'
            '4. 信息共享：未经您的同意，我们不会向第三方分享您的个人信息。\n\n'
            '5. 用户权利：您可以随时查看、修改或删除您的个人信息。',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSilver,
              height: 1.8,
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: _buildDialogButton(
              text: '我已阅读',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 用户协议对话框 =====
  void _showUserAgreementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        title: '用户协议',
        child: const SingleChildScrollView(
          child: Text(
            '欢迎使用音浪AI。在使用本应用前，请仔细阅读以下协议条款。\n\n'
            '1. 服务条款：本应用提供AI音乐创作服务，用户应合法使用。\n\n'
            '2. 用户责任：用户对其创作内容负责，不得发布违法违规内容。\n\n'
            '3. 知识产权：用户使用AI生成的音乐作品，版权归用户所有。\n\n'
            '4. 服务变更：我们保留随时修改或终止服务的权利。\n\n'
            '5. 免责声明：本服务按"现状"提供，不作任何明示或暗示的保证。',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSilver,
              height: 1.8,
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: _buildDialogButton(
              text: '我已阅读',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
