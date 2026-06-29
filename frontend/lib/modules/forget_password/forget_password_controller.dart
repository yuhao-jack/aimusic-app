import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

class ForgetPasswordController extends GetxController {
  final ApiService api = Get.find<ApiService>();

  final emailController = TextEditingController();
  RxBool isLoading = false.obs;
  RxBool codeSent = false.obs;
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  RxBool obscurePassword = true.obs;

  void togglePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> sendCode() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar('提示', '请输入邮箱');
      return;
    }

    isLoading.value = true;

    try {
      final response = await api.post('/user/send-reset-code', data: {
        'email': email,
      });

      if (response['code'] == 0) {
        codeSent.value = true;
        Get.snackbar('成功', '验证码已发送到您的邮箱');
      }
    } catch (e) {
      // 错误已经在HttpUtil拦截器中处理了
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();
    final newPassword = newPasswordController.text.trim();

    if (email.isEmpty) {
      Get.snackbar('提示', '请输入邮箱');
      return;
    }
    if (code.isEmpty) {
      Get.snackbar('提示', '请输入验证码');
      return;
    }
    if (newPassword.isEmpty) {
      Get.snackbar('提示', '请输入新密码');
      return;
    }
    if (newPassword.length < 6) {
      Get.snackbar('提示', '密码长度不能少于6位');
      return;
    }

    isLoading.value = true;

    try {
      final response = await api.post('/user/reset-password', data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });

      if (response['code'] == 0) {
        Get.snackbar('成功', '密码重置成功，请重新登录');
        Get.back();
      }
    } catch (e) {
      // 错误已经在HttpUtil拦截器中处理了
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    super.onClose();
  }
}
