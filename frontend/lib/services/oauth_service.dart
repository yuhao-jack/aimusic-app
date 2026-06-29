import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/utils/toast_util.dart';

/// OAuth 第三方登录服务
/// 注意：需要安装 google_sign_in 和 sign_in_with_apple 包后才能使用
/// flutter pub add google_sign_in sign_in_with_apple
class OAuthService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  /// Google登录
  /// TODO: 安装 google_sign_in 包后实现
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    ToastUtil.info('Google登录功能即将开放');
    return null;
  }

  /// Apple登录
  /// TODO: 安装 sign_in_with_apple 包后实现
  Future<Map<String, dynamic>?> signInWithApple() async {
    ToastUtil.info('Apple登录功能即将开放');
    return null;
  }

  /// 通用OAuth登录（调用后端接口）
  Future<Map<String, dynamic>?> loginWithOAuth({
    required String openId,
    required String provider,
    String? nickname,
    String? avatar,
    String? email,
  }) async {
    try {
      final response = await _api.post('/user/login/oauth', data: {
        'open_id': openId,
        'provider': provider,
        if (nickname != null) 'nickname': nickname,
        if (avatar != null) 'avatar': avatar,
        if (email != null) 'email': email,
      });

      if (response['code'] == 0) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('$provider 登录失败: $e');
      ToastUtil.showError('登录失败，请重试');
      return null;
    }
  }
}
