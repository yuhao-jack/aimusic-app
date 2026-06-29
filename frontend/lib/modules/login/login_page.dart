import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/modules/login/login_controller.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

/// 登录页 - 简约毛玻璃科技感设计
class LoginPage extends GetView<LoginController> {
  /// 第三方登录开关 — 集成SDK后改为true启用
  static const bool _enableSocialLogin = true;

  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.surface1,
              AppTheme.surface2,
            ],
          ),
        ),
        child: Stack(
          children: [
            // ===== 顶部靛蓝光晕装饰 =====
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(0.3, 0.3),
                    radius: 0.8,
                    colors: [
                      AppTheme.brandIndigo.withValues(alpha: 0.15),
                      AppTheme.brandPurple.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ===== 主内容 =====
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),

                    // ===== Logo（紧凑） =====
                    FadeInWidget(
                      delay: const Duration(milliseconds: 100),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.secondaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            size: 38,
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== 标题文字 =====
                    const FadeInWidget(
                      delay: Duration(milliseconds: 200),
                      child: Text(
                        '欢迎回来',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const FadeInWidget(
                      delay: Duration(milliseconds: 300),
                      child: Text(
                        '登录后继续创作音乐',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSilver,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ===== 毛玻璃卡片容器 =====
                    FadeInWidget(
                      delay: const Duration(milliseconds: 350),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface3.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.borderSubtle,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ===== 用户名输入框 =====
                            _buildInputField(
                              controller: controller.emailController,
                              icon: Icons.person_outline,
                              hint: '用户名或邮箱',
                            ),
                            const SizedBox(height: 14),

                            // ===== 密码输入框 =====
                            Obx(
                              () => _buildPasswordField(
                                passwordController: controller.passwordController,
                                obscureText: controller.obscurePassword.value,
                                onToggle: controller.togglePassword,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ===== 忘记密码 =====
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => Get.toNamed(AppRoutes.forgetPassword),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '忘记密码？',
                                    style: TextStyle(
                                      color: AppTheme.brandIndigo,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ===== 登录按钮 =====
                            Obx(
                              () => _buildLoginButton(
                                isLoading: controller.isLoading.value,
                                onPressed: controller.login,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== 分隔线 + 社交登录（配置开关控制显示） =====
                    if (_enableSocialLogin) ...[
                      FadeInWidget(
                        delay: const Duration(milliseconds: 400),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 0.5,
                                color: AppTheme.borderGray.withValues(alpha: 0.25),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                '或',
                                style: TextStyle(
                                  color: AppTheme.textLightGray,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 0.5,
                                color: AppTheme.borderGray.withValues(alpha: 0.25),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ===== 社交登录 =====
                      FadeInWidget(
                        delay: const Duration(milliseconds: 450),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              icon: Icons.phone,
                              label: '手机号',
                              onPressed: () => _showPhoneLoginDialog(context),
                            ),
                            const SizedBox(width: 12),
                            _buildSocialButton(
                              icon: Icons.g_mobiledata,
                              label: 'Google',
                              onPressed: () => controller.googleLogin(),
                            ),
                            const SizedBox(width: 12),
                            _buildSocialButton(
                              icon: Icons.apple,
                              label: 'Apple',
                              onPressed: () => controller.appleLogin(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ===== 注册链接 =====
                    FadeInWidget(
                      delay: const Duration(milliseconds: 500),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '还没有账号？',
                            style: TextStyle(
                              color: AppTheme.textSilver,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.register),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '注册',
                                style: TextStyle(
                                  color: AppTheme.brandIndigo,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 输入框 =====
  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppTheme.textWhite, fontSize: 15),
      cursorColor: AppTheme.brandIndigo,
      cursorWidth: 2,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.surface3.withValues(alpha: 0.6),
        prefixIcon: Icon(icon, color: AppTheme.textLightGray, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppTheme.textDarkGray,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.brandIndigo,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ===== 密码输入框 =====
  Widget _buildPasswordField({
    required TextEditingController passwordController,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: passwordController,
      obscureText: obscureText,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => controller.login(),
      style: const TextStyle(color: AppTheme.textWhite, fontSize: 15),
      cursorColor: AppTheme.brandIndigo,
      cursorWidth: 2,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.surface3.withValues(alpha: 0.6),
        prefixIcon:
            const Icon(Icons.lock_outline, color: AppTheme.textLightGray, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppTheme.textLightGray,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        hintText: '密码',
        hintStyle: const TextStyle(
          color: AppTheme.textDarkGray,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
      ),
    );
  }

  // ===== 登录按钮 =====
  Widget _buildLoginButton({
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return ElasticButton(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryToSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandIndigo.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.textWhite,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  '登录',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                    letterSpacing: 1.4,
                  ),
                ),
        ),
      ),
    );
  }

  // ===== 社交登录按钮 =====
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElasticButton(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: 96,
        decoration: BoxDecoration(
          color: AppTheme.surface2.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderGray.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textWhite, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSilver,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 手机号登录对话框 =====
  void _showPhoneLoginDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final codeController = TextEditingController();
    Get.defaultDialog(
      title: '手机号登录',
      titleStyle: const TextStyle(
        color: AppTheme.textWhite,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppTheme.surface3,
      radius: 16,
      content: Column(
        children: [
          // 手机号输入框
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surface2,
              prefixIcon: const Icon(Icons.phone, color: AppTheme.textLightGray, size: 20),
              hintText: '请输入手机号',
              hintStyle: const TextStyle(color: AppTheme.textLightGray, fontSize: 14),
              counterText: '', // 隐藏字数统计
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
          ),
          const SizedBox(height: 14),
          // 验证码输入框 + 获取验证码按钮
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surface2,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textLightGray, size: 20),
                    hintText: '验证码',
                    hintStyle: const TextStyle(color: AppTheme.textLightGray, fontSize: 14),
                    counterText: '', // 隐藏字数统计
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 获取验证码按钮（带倒计时）
              Obx(() => SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: controller.countdown.value > 0 || controller.isSendingCode.value
                      ? null
                      : () => controller.sendSmsCode(phoneController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.countdown.value > 0
                        ? AppTheme.surface2
                        : AppTheme.brandIndigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    controller.countdown.value > 0
                        ? '${controller.countdown.value}s后重试'
                        : '获取验证码',
                    style: TextStyle(
                      color: controller.countdown.value > 0
                          ? AppTheme.textLightGray
                          : AppTheme.textWhite,
                      fontSize: 13,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
      // 登录按钮
      confirm: Obx(() => SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : () {
                  controller.loginByPhone(
                    phoneController.text.trim(),
                    codeController.text.trim(),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandIndigo,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.textWhite,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text('登录', style: TextStyle(color: AppTheme.textWhite, fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      )),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('取消', style: TextStyle(color: AppTheme.textSilver)),
      ),
    );
  }

}
