import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/services/oauth_service.dart';
import 'package:aimusic_app/global/user_controller.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/utils/toast_util.dart';

class LoginController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final OAuthService _oauth = Get.find<OAuthService>();
  
  // 不在初始化时直接获取，而是使用时再获取
  UserController get userController => UserController.to;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  RxBool obscurePassword = true.obs;
  RxBool isLoading = false.obs;

  // 手机号登录相关
  RxInt countdown = 0.obs; // 倒计时秒数
  RxBool isSendingCode = false.obs; // 是否正在发送验证码
  Timer? _countdownTimer; // 倒计时定时器

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      ToastUtil.showWarning('请输入邮箱/用户名');
      return;
    }
    if (password.isEmpty) {
      ToastUtil.showWarning('请输入密码');
      return;
    }

    isLoading.value = true;

    try {
      // ===== 真实API登录 =====
      debugPrint('尝试登录: $email');
      final response = await _api.post('/user/login', data: {
        'username': email,
        'password': password,
      });

      debugPrint('登录响应: $response');

      if (response != null && response['code'] == 0) {
        final data = response['data'];
        final String token = data['token'] ?? '';
        final Map<String, dynamic> userInfo = Map<String, dynamic>.from(data['user'] ?? {});
        
        if (token.isEmpty) {
          ToastUtil.showError('登录失败：未获取到token');
          return;
        }
        
        userController.loginSuccess(token, userInfo);
        ToastUtil.showSuccess('登录成功');
        Get.offAllNamed(AppRoutes.home);
      } else {
        final msg = response?['message'] ?? response?['msg'] ?? '登录失败';
        ToastUtil.showError(msg);
      }
    } catch (e) {
      debugPrint('登录异常: $e');
      if (e.toString().contains('401')) {
        ToastUtil.showError('用户名或密码错误');
      } else if (e.toString().contains('Connection') || e.toString().contains('Socket')) {
        ToastUtil.showError('网络连接失败，请检查服务器地址');
      } else {
        ToastUtil.showError('登录失败，请重试');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Google登录
  Future<void> googleLogin() async {
    isLoading.value = true;
    try {
      final data = await _oauth.signInWithGoogle();
      if (data != null) {
        final String token = data['token'];
        final Map<String, dynamic> userInfo = data['user'];
        userController.loginSuccess(token, userInfo);
        ToastUtil.showSuccess('登录成功');
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      ToastUtil.showError('Google登录失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Apple登录
  Future<void> appleLogin() async {
    isLoading.value = true;
    try {
      final data = await _oauth.signInWithApple();
      if (data != null) {
        final String token = data['token'];
        final Map<String, dynamic> userInfo = data['user'];
        userController.loginSuccess(token, userInfo);
        ToastUtil.showSuccess('登录成功');
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      ToastUtil.showError('Apple登录失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void togglePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  // 发送短信验证码
  Future<void> sendSmsCode(String phone) async {
    if (phone.isEmpty) {
      ToastUtil.showWarning('请输入手机号');
      return;
    }
    if (phone.length != 11) {
      ToastUtil.showWarning('请输入正确的手机号');
      return;
    }

    isSendingCode.value = true;
    try {
      final response = await _api.post('/user/send-sms-code', data: {
        'phone': phone,
      });

      if (response['code'] == 0) {
        ToastUtil.showSuccess('验证码已发送');
        // 开发环境：如果返回了验证码，显示提示
        if (response['data'] != null && response['data']['code'] != null) {
          ToastUtil.showInfo('开发环境验证码: ${response['data']['code']}');
        }
        // 开始60秒倒计时
        _startCountdown();
      } else {
        ToastUtil.showError(response['message'] ?? '发送失败');
      }
    } catch (e) {
      ToastUtil.showError('发送失败: $e');
    } finally {
      isSendingCode.value = false;
    }
  }

  // 开始倒计时
  void _startCountdown() {
    countdown.value = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        timer.cancel();
        _countdownTimer = null;
      }
    });
  }

  // 手机号验证码登录
  Future<void> loginByPhone(String phone, String code) async {
    if (phone.isEmpty) {
      ToastUtil.showWarning('请输入手机号');
      return;
    }
    if (phone.length != 11) {
      ToastUtil.showWarning('请输入正确的手机号');
      return;
    }
    if (code.isEmpty) {
      ToastUtil.showWarning('请输入验证码');
      return;
    }
    if (code.length != 6) {
      ToastUtil.showWarning('请输入6位验证码');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _api.post('/user/login/phone', data: {
        'phone': phone,
        'code': code,
      });

      if (response['code'] == 0) {
        final data = response['data'];
        final String token = data['token'];
        final Map<String, dynamic> userInfo = data['user'];
        userController.loginSuccess(token, userInfo);
        ToastUtil.showSuccess('登录成功');
        Get.offAllNamed(AppRoutes.home);
      } else {
        ToastUtil.showError(response['message'] ?? '登录失败');
      }
    } catch (e) {
      ToastUtil.showError('登录失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Google登录
  Future<void> loginWithGoogle() async {
    try {
      final result = await _oauth.signInWithGoogle();
      if (result != null) {
        _handleOAuthResult(result);
      }
    } catch (e) {
      ToastUtil.showError('Google登录失败: $e');
    }
  }

  /// Apple登录
  Future<void> loginWithApple() async {
    try {
      final result = await _oauth.signInWithApple();
      if (result != null) {
        _handleOAuthResult(result);
      }
    } catch (e) {
      ToastUtil.showError('Apple登录失败: $e');
    }
  }

  /// 微信登录
  Future<void> loginWithWechat() async {
    ToastUtil.showInfo('微信登录功能即将开放');
  }

  /// 处理OAuth登录结果
  void _handleOAuthResult(Map<String, dynamic> result) {
    final String? token = result['token'];
    final Map<String, dynamic>? userInfo = result['user'];
    if (token != null && userInfo != null) {
      userController.loginSuccess(token, userInfo);
      ToastUtil.showSuccess('登录成功');
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
