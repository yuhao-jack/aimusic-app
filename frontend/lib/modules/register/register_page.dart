import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/modules/register/register_controller.dart';

class RegisterPage extends GetView<RegisterController> {
  RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textWhite, size: 20),
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== Title =====
              Text(
                '创建账号',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                  height: 1.25,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '加入我们，开始创作精彩的音乐',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSilver,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 40),

              // ===== Username Input =====
              _buildInputField(
                controller: controller.usernameController,
                icon: Icons.person_outline,
                label: '用户名',
                hint: '请输入用户名',
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16),

              // ===== Email Input =====
              _buildInputField(
                controller: controller.emailController,
                icon: Icons.email_outlined,
                label: '邮箱',
                hint: '请输入邮箱地址',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16),

              // ===== Password Input =====
              Obx(() => _buildPasswordField(
                    controller: controller.passwordController,
                    obscureText: controller.obscurePassword.value,
                    onToggle: controller.togglePassword,
                    label: '密码',
                    hint: '请输入密码',
                    textInputAction: TextInputAction.next,
                  )),
              SizedBox(height: 16),

              // ===== Confirm Password Input =====
              Obx(() => _buildPasswordField(
                    controller: controller.confirmPasswordController,
                    obscureText: controller.obscureConfirmPassword.value,
                    onToggle: controller.toggleConfirmPassword,
                    label: '确认密码',
                    hint: '请再次输入密码',
                    textInputAction: TextInputAction.done,
                  )),
              SizedBox(height: 20),

              // ===== Terms Checkbox =====
              Obx(() => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: controller.agreeTerms.value,
                        onChanged: (value) {
                          controller.agreeTerms.value = value ?? false;
                        },
                        activeColor: AppTheme.primaryColor,
                        checkColor: AppTheme.textWhite,
                        side: BorderSide(color: AppTheme.textLightGray),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            controller.agreeTerms.value = !controller.agreeTerms.value;
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSilver,
                                height: 1.5,
                              ),
                              text: '我已阅读并同意',
                              children: [
                                TextSpan(
                                  text: '服务条款',
                                  style: TextStyle(color: AppTheme.primaryColor),
                                ),
                                TextSpan(
                                  text: '和',
                                ),
                                TextSpan(
                                  text: '隐私政策',
                                  style: TextStyle(color: AppTheme.primaryColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
              SizedBox(height: 32),

              // ===== Register Button =====
              Obx(() => _buildRegisterButton(
                    isLoading: controller.isLoading.value,
                    onPressed: controller.register,
                  )),
              SizedBox(height: 32),

              // ===== Login Link =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '已有账号？',
                    style: TextStyle(
                      color: AppTheme.textSilver,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: Text(
                      '登录',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Input Field Widget =====
  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: TextStyle(color: AppTheme.textWhite),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.surface3,
        prefixIcon: Icon(icon, color: AppTheme.textLightGray),
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textLightGray),
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textLightGray),
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
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 1,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ===== Password Field Widget =====
  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required String label,
    required String hint,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      style: TextStyle(color: AppTheme.textWhite),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.surface3,
        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textLightGray),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppTheme.textLightGray,
          ),
          onPressed: onToggle,
        ),
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textLightGray),
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textLightGray),
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
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 1,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ===== Register Button Widget =====
  Widget _buildRegisterButton({
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.textWhite,
          disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
          elevation: AppTheme.elevationNone,
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryToSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.textWhite,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    '注册',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
