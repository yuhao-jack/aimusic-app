import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/global/user_controller.dart';
import 'package:aimusic_app/utils/storage_util.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/utils/api_config.dart';
import 'package:aimusic_app/routes/app_routes.dart';

class AuthService extends GetxService {
  final ApiService _api = Get.find<ApiService>();
  
  // 不在初始化时直接获取，而是使用时再获取
  UserController get _userController => UserController.to;

  // 是否正在刷新Token
  final RxBool _isRefreshing = false.obs;

  // 登录（用户名/密码）
  Future<bool> loginByPassword({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _api.post('/user/login', data: {
        'username': username,
        'password': password,
      });

      if (response['code'] == 0) {
        final data = response['data'];
        final String token = data['token'];
        final String? refreshToken = data['refresh_token'];
        final Map<String, dynamic> userInfo = data['user'];
        
        // 保存 token 和 refresh_token
        await StorageUtil.setString('token', token);
        if (refreshToken != null) {
          await StorageUtil.setString('refresh_token', refreshToken);
        }
        
        _userController.loginSuccess(token, userInfo);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('登录失败: $e');
      return false;
    }
  }

  // 登录（手机号验证码）
  Future<bool> loginByPhone({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _api.post('/user/login/phone', data: {
        'phone': phone,
        'code': code,
      });

      if (response['code'] == 0) {
        final data = response['data'];
        final String token = data['token'];
        final String? refreshToken = data['refresh_token'];
        final Map<String, dynamic> userInfo = data['user'];
        
        // 保存 token 和 refresh_token
        await StorageUtil.setString('token', token);
        if (refreshToken != null) {
          await StorageUtil.setString('refresh_token', refreshToken);
        }
        
        _userController.loginSuccess(token, userInfo);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('登录失败: $e');
      return false;
    }
  }

  // 注册
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/user/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('注册失败: $e');
      return false;
    }
  }

  // 发送重置密码验证码
  Future<bool> sendResetCode({
    required String email,
  }) async {
    try {
      final response = await _api.post('/user/send-reset-code', data: {
        'email': email,
      });

      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('发送验证码失败: $e');
      return false;
    }
  }

  // 重置密码
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _api.post('/user/reset-password', data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });

      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('重置密码失败: $e');
      return false;
    }
  }

  // 退出登录
  Future<void> logout() async {
    _userController.logout();
    ToastUtil.showInfo('已退出登录');
    Get.offAllNamed(AppRoutes.login);
  }

  // 处理401错误（Token过期）
  Future<void> handle401() async {
    if (_isRefreshing.value) {
      return;
    }

    _isRefreshing.value = true;

    try {
      // 尝试刷新Token
      final success = await refreshToken();
      if (!success) {
        // 刷新失败，退出登录
        await logout();
      }
    } catch (e) {
      debugPrint('处理401错误失败: $e');
      await logout();
    } finally {
      _isRefreshing.value = false;
    }
  }

  // 刷新Token
  Future<bool> refreshToken() async {
    try {
      // 从本地存储读取 refresh_token
      final String? refreshToken = StorageUtil.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('刷新Token失败: refresh_token不存在');
        return false;
      }

      // 使用独立的 Dio 实例（不带拦截器）调用刷新接口
      final Dio refreshDio = Dio(BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
        },
      ));

      final response = await refreshDio.post(
        '/user/refresh-token',
        data: {'refresh_token': refreshToken},
      );

      if (response.data != null && response.data['code'] == 0) {
        final String newToken = response.data['data']['token'];
        final String? newRefreshToken = response.data['data']['refresh_token'];
        
        // 保存新的 token
        await StorageUtil.setString('token', newToken);
        
        // 如果返回了新的 refresh_token，也保存
        if (newRefreshToken != null) {
          await StorageUtil.setString('refresh_token', newRefreshToken);
        }
        
        debugPrint('Token刷新成功');
        return true;
      }
    } catch (e) {
      debugPrint('刷新Token失败: $e');
    }
    return false;
  }
}
