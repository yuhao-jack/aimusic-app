import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/utils/storage_util.dart';
import 'package:aimusic_app/services/user_service.dart';

class UserController extends GetxController {
  static UserController get to => Get.find();

  // 不在初始化时直接Get.find，而是使用时再获取
  UserService get _userService => Get.find<UserService>();

  // 用户信息
  final RxMap<String, dynamic> _userInfo = <String, dynamic>{}.obs;
  Map<String, dynamic> get userInfo => _userInfo;

  // 是否登录
  final RxBool _isLogin = false.obs;
  bool get isLogin => _isLogin.value;

  @override
  void onInit() {
    super.onInit();
    debugPrint('UserController: onInit 被调用');
    // 初始化读取本地存储的用户信息
    try {
      _initUserInfo();
    } catch (e) {
      debugPrint('UserController初始化错误: $e');
      _isLogin.value = false;
    }
  }

  // 初始化用户信息
  void _initUserInfo() {
    try {
      String? token = StorageUtil.getString('token');
      Map<String, dynamic>? userInfo = StorageUtil.getJson('user_info');
      if (token != null && token.isNotEmpty && userInfo != null) {
        _userInfo.value = userInfo;
        _isLogin.value = true;
        debugPrint('UserController: 已登录，用户信息 = $userInfo');
        // 如果已登录，从后端获取最新用户信息
        _refreshUserInfo();
      } else {
        _isLogin.value = false;
        debugPrint('UserController: 未登录');
      }
    } catch (e) {
      debugPrint('读取用户信息失败: $e');
      _isLogin.value = false;
    }
  }

  // 从后端刷新用户信息
  Future<void> _refreshUserInfo() async {
    try {
      await _userService.fetchUserInfo();
    } catch (e) {
      debugPrint('刷新用户信息失败: $e');
    }
  }

  // 公共方法：重新加载用户信息
  Future<void> loadUserInfo() async {
    await _refreshUserInfo();
  }

  // 保存用户信息到本地存储
  void _saveUserInfoToStorage(Map<String, dynamic> userInfo) {
    StorageUtil.setJson('user_info', userInfo);
  }

  // 从服务更新用户信息
  void updateUserInfoFromService(Map<String, dynamic> userInfo) {
    _userInfo.value = userInfo;
    _saveUserInfoToStorage(userInfo);
  }

  // 登录成功，保存用户信息
  void loginSuccess(String token, Map<String, dynamic> userInfo, {String? refreshToken}) {
    StorageUtil.setString('token', token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      StorageUtil.setString('refresh_token', refreshToken);
    }
    _userInfo.value = userInfo;
    _saveUserInfoToStorage(userInfo);
    _isLogin.value = true;
    debugPrint('UserController: 登录成功');
  }

  // 更新用户信息
  Future<bool> updateUserInfo({
    String? nickname,
    String? avatar,
  }) async {
    final success = await _userService.updateUserInfo(
      nickname: nickname,
      avatar: avatar,
    );
    return success;
  }

  // 退出登录
  void logout() {
    StorageUtil.remove('token');
    StorageUtil.remove('user_info');
    _userInfo.clear();
    _isLogin.value = false;
    debugPrint('UserController: 已退出登录');
  }
}
