import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/modules/login/login_controller.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

/// 登录页 - 简约毛玻璃科技感设计
class LoginPage extends GetView<LoginController> {
  LoginPage({super.key});

  // 登录方式配置
  final RxMap<String, dynamic> loginConfig = <String, dynamic>{
    'login_email': 'true',
    'login_phone': 'false',
    'login_google': 'false',
    'login_apple': 'false',
    'login_wechat': 'false',
  }.obs;

  @override
  Widget build(BuildContext context) {
    // 加载登录配置
    _loadLoginConfig();

    return Scaffold(
      backgroundColor: AppTheme.surface1,
      body: Container(
        decoration: BoxDecoration(
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
                    center: Alignment(0.3, 0.3),
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
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 48),

                    // ===== Logo =====
                    FadeInWidget(
                      delay: Duration(milliseconds: 100),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.secondaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: AppTheme.textWhite,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // ===== 标题 =====
                    FadeInWidget(
                      delay: Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          Text(
                            '欢迎回来',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textWhite,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '登录你的账号继续',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSilver,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),

                    // ===== 邮箱登录表单 =====
                    FadeInWidget(
                      delay: Duration(milliseconds: 300),
                      child: _buildEmailLoginForm(),
                    ),
                    SizedBox(height: 16),

                    // ===== 邮箱验证码登录按钮 =====
                    Obx(() {
                      if (loginConfig['login_email'] == 'true') {
                        return FadeInWidget(
                          delay: Duration(milliseconds: 350),
                          child: _buildLoginButton(
                            isLoading: controller.isLoading.value,
                            onPressed: () => controller.login(),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    }),
                    SizedBox(height: 20),

                    // ===== 其他登录方式 =====
                    Obx(() {
                      final hasPhone = loginConfig['login_phone'] == 'true';
                      final hasGoogle = loginConfig['login_google'] == 'true';
                      final hasApple = loginConfig['login_apple'] == 'true';
                      final hasWechat = loginConfig['login_wechat'] == 'true';

                      if (!hasPhone && !hasGoogle && !hasApple && !hasWechat) {
                        return SizedBox.shrink();
                      }

                      return FadeInWidget(
                        delay: Duration(milliseconds: 400),
                        child: Column(
                          children: [
                            // 分隔线
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppTheme.borderSubtle, thickness: 0.5)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('其他登录方式', style: TextStyle(color: AppTheme.textLightGray, fontSize: 12)),
                                ),
                                Expanded(child: Divider(color: AppTheme.borderSubtle, thickness: 0.5)),
                              ],
                            ),
                            SizedBox(height: 20),

                            // 登录按钮
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                if (hasPhone)
                                  _buildSocialButton(
                                    icon: Icons.phone_rounded,
                                    label: '手机登录',
                                    onPressed: () => _showPhoneLoginDialog(Get.context!),
                                  ),
                                if (hasGoogle)
                                  _buildSocialButton(
                                    icon: Icons.g_mobiledata_rounded,
                                    label: 'Google',
                                    onPressed: () => controller.loginWithGoogle(),
                                  ),
                                if (hasApple)
                                  _buildSocialButton(
                                    icon: Icons.apple_rounded,
                                    label: 'Apple',
                                    onPressed: () => controller.loginWithApple(),
                                  ),
                                if (hasWechat)
                                  _buildSocialButton(
                                    icon: Icons.wechat_rounded,
                                    label: '微信',
                                    onPressed: () => controller.loginWithWechat(),
                                  ),
                              ],
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                      );
                    }),

                    // ===== 底部 =====
                    FadeInWidget(
                      delay: Duration(milliseconds: 500),
                      child: Center(
                        child: TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.register),
                          child: Text(
                            '没有账号？去注册',
                            style: TextStyle(
                              color: AppTheme.textLightGray,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 加载登录配置
  Future<void> _loadLoginConfig() async {
    try {
      final api = Get.find<ApiService>();
      final response = await api.get('/system/config');
      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        loginConfig.value = {
          'login_email': data['login_email'] ?? 'true',
          'login_phone': data['login_phone'] ?? 'false',
          'login_google': data['login_google'] ?? 'false',
          'login_apple': data['login_apple'] ?? 'false',
          'login_wechat': data['login_wechat'] ?? 'false',
        };
      }
    } catch (e) {
      debugPrint('加载登录配置失败: $e');
    }
  }

  // ===== 邮箱登录表单 =====
  Widget _buildEmailLoginForm() {
    return Column(
      children: [
        // 邮箱输入框
        _buildInputField(
          controller: controller.emailController,
          icon: Icons.email_outlined,
          hintText: '请输入邮箱',
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 14),

        // 密码输入框
        Obx(() => _buildInputField(
          controller: controller.passwordController,
          icon: Icons.lock_outline,
          hintText: '请输入密码',
          obscureText: controller.obscurePassword.value,
          suffixIcon: IconButton(
            icon: Icon(
              controller.obscurePassword.value
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.textLightGray,
              size: 20,
            ),
            onPressed: () => controller.obscurePassword.toggle(),
          ),
        )),
      ],
    );
  }

  // ===== 输入框组件 =====
  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface2.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderGray.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(
          color: AppTheme.textWhite,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.textLightGray, size: 20),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppTheme.textLightGray,
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
            borderSide: BorderSide(
              color: AppTheme.primaryColor,
              width: 1,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
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
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.textWhite,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
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
        padding: EdgeInsets.symmetric(vertical: 12),
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
            SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
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
      titleStyle: TextStyle(
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
            style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surface2,
              prefixIcon: Icon(Icons.phone, color: AppTheme.textLightGray, size: 20),
              hintText: '请输入手机号',
              hintStyle: TextStyle(color: AppTheme.textLightGray, fontSize: 14),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
          ),
          SizedBox(height: 14),
          // 验证码输入框 + 获取验证码按钮
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surface2,
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textLightGray, size: 20),
                    hintText: '验证码',
                    hintStyle: TextStyle(color: AppTheme.textLightGray, fontSize: 14),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ),
              SizedBox(width: 10),
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
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.textWhite,
                    strokeWidth: 2.5,
                  ),
                )
              : Text('登录', style: TextStyle(color: AppTheme.textWhite, fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      )),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text('取消', style: TextStyle(color: AppTheme.textSilver)),
      ),
    );
  }
}
