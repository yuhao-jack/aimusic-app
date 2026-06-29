import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/global/user_controller.dart';
import 'package:aimusic_app/utils/dialog_util.dart';

class UserService extends GetxService {
  final ApiService _api = Get.find<ApiService>();
  
  // 不在初始化时直接获取，而是使用时再获取
  UserController get _userController => UserController.to;

  // 获取用户信息
  Future<void> fetchUserInfo() async {
    try {
      final response = await _api.get('/user/info');
      if (response['code'] == 0) {
        final userInfo = response['data'];
        // 更新用户信息
        _userController.updateUserInfoFromService(userInfo);
      }
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
    }
  }

  // 更新用户信息
  Future<bool> updateUserInfo({
    String? nickname,
    String? avatar,
  }) async {
    try {
      DialogUtil.showLoading(message: '更新中...');
      
      final data = <String, dynamic>{};
      if (nickname != null) data['nickname'] = nickname;
      if (avatar != null) data['avatar'] = avatar;
      
      final response = await _api.put('/user/info', data: data);
      
      DialogUtil.hideLoading();
      
      if (response['code'] == 0) {
        // 重新获取用户信息
        await fetchUserInfo();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      DialogUtil.hideLoading();
      debugPrint('更新用户信息失败: $e');
      return false;
    }
  }

  // 获取用户作品
  Future<List<dynamic>?> fetchUserWorks() async {
    try {
      final response = await _api.get('/user/works');
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取用户作品失败: $e');
    }
    return null;
  }

  // 获取用户喜欢
  Future<List<dynamic>?> fetchUserLikes() async {
    try {
      final response = await _api.get('/user/likes');
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取用户喜欢失败: $e');
    }
    return null;
  }
}
