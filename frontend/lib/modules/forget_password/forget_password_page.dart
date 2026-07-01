import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/modules/forget_password/forget_password_controller.dart';

class ForgetPasswordPage extends GetView<ForgetPasswordController> {
  ForgetPasswordPage({super.key});

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
                '重置密码',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                  height: 1.25,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '我们会发送验证码到您的邮箱',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSilver,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 40),

              // ===== Email Input =====
              _buildInputField(
                controller: controller.emailController,
                icon: Icons.email_outlined,
                label: '邮箱',
                hint: '请输入注册邮箱',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 20),

              Obx(() {
                if (!controller.codeSent.value) {
                  return _buildSendCodeButton(
                    isLoading: controller.isLoading.value,
                    onPressed: controller.sendCode,
                  );
                }

                return Column(
                  children: [
                  // ===== Code Input =====
                  _buildInputField(
                    controller: controller.codeController,
                    icon: Icons.pin_outlined,
                    label: '验证码',
                    hint: '请输入邮箱收到的验证码',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16),

                  // ===== New Password Input =====
                  Obx(() => _buildPasswordField(
                    controller: controller.newPasswordController,
                    obscureText: controller.obscurePassword.value,
                    onToggle: controller.togglePassword,
                    label: '新密码',
                    hint: '请输入新密码（至少6位）',
                    textInputAction: TextInputAction.done,
                  )),
                  SizedBox(height: 32),

                  // ===== Reset Button =====
                  Obx(() => _buildResetButton(
                    isLoading: controller.isLoading.value,
                    onPressed: controller.resetPassword,
                  )),
                ],
              );
              }),

              SizedBox(height: 20),

              // ===== Back to Login =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '想起密码了？',
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
                      '返回登录',
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

  // ===== Send Code Button Widget =====
  Widget _buildSendCodeButton({
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
                    '发送验证码',
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

  // ===== Reset Button Widget =====
  Widget _buildResetButton({
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
                    '确认重置',
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
