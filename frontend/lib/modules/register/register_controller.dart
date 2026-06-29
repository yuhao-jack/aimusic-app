import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/theme/app_theme.dart';

class RegisterController extends GetxController {
  final ApiService api = Get.find<ApiService>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  RxBool obscurePassword = true.obs;
  RxBool obscureConfirmPassword = true.obs;
  RxBool isLoading = false.obs;
  RxBool agreeTerms = false.obs;

  void togglePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPassword() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  Future<void> register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // 表单验证
    if (username.isEmpty) {
      Get.snackbar(
        '提示', 
        '请输入用户名',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: AppTheme.textWhite,
      );
      return;
    }
    if (email.isEmpty) {
      Get.snackbar(
        '提示', 
        '请输入邮箱',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: AppTheme.textWhite,
      );
      return;
    }
    if (password.isEmpty) {
      Get.snackbar(
        '提示', 
        '请输入密码',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: AppTheme.textWhite,
      );
      return;
    }
    if (password.length < 6) {
      Get.snackbar(
        '提示', 
        '密码长度不能少于6位',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: AppTheme.textWhite,
      );
      return;
    }
    if (password != confirmPassword) {
      Get.snackbar(
        '提示', 
        '两次输入的密码不一致',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: AppTheme.textWhite,
      );
      return;
    }
    if (!agreeTerms.value) {
      Get.snackbar(
        '提示', 
        '请先同意用户协议和隐私政策',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: AppTheme.textWhite,
      );
      return;
    }

    isLoading.value = true;

    try {
      // ===== 真实API注册 =====
      final response = await api.post('/user/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      if (response['code'] == 0) {
        Get.snackbar(
          '成功', 
          '注册成功，请登录',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.successColor,
          colorText: AppTheme.textWhite,
        );
        Get.back();
      } else {
        Get.snackbar(
          '错误', 
          response['message'] ?? '注册失败',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.errorColor,
          colorText: AppTheme.textWhite,
        );
      }
    } catch (e) {
      Get.snackbar(
        '错误', 
        '注册失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorColor,
        colorText: AppTheme.textWhite,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
