import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aimusic_app/global/user_controller.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/utils/http_util.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/theme/theme_provider.dart';

class SettingsController extends GetxController {
  final UserController userController = UserController.to;

  // 开关状态
  final RxBool darkMode = true.obs;
  final RxBool notifications = true.obs;
  final RxBool wifiOnlyDownload = true.obs;
  final RxBool autoPlay = false.obs;

  /// 绑定手机弹窗 - 倒计时秒数
  final RxInt phoneCountdown = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  // 从本地存储加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    darkMode.value = prefs.getBool('darkMode') ?? true;
    notifications.value = prefs.getBool('notifications') ?? true;
    wifiOnlyDownload.value = prefs.getBool('wifiOnlyDownload') ?? true;
    autoPlay.value = prefs.getBool('autoPlay') ?? false;
  }

  // 保存设置到本地存储
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode.value);
    await prefs.setBool('notifications', notifications.value);
    await prefs.setBool('wifiOnlyDownload', wifiOnlyDownload.value);
    await prefs.setBool('autoPlay', autoPlay.value);
  }

  // 更新深色模式 - 立即生效
  void updateDarkMode(bool value) {
    darkMode.value = value;
    saveSettings();
    // 切换主题模式
    ThemeProvider.to.setThemeMode(value ? ThemeModeOption.dark : ThemeModeOption.light);
  }

  // 更新通知开关
  void updateNotifications(bool value) {
    notifications.value = value;
    saveSettings();
  }

  // 更新仅WiFi下载开关
  void updateWifiOnlyDownload(bool value) {
    wifiOnlyDownload.value = value;
    saveSettings();
  }

  // 更新自动播放开关
  void updateAutoPlay(bool value) {
    autoPlay.value = value;
    saveSettings();
  }

  /// 修改密码
  Future<void> changePassword(String newPwd) async {
    try {
      ToastUtil.showLoading('修改中...');
      await HttpUtil().put('/user/info', data: {
        'password': newPwd,
      });
      ToastUtil.hideLoading();
      ToastUtil.success('密码修改成功，请重新登录');
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      ToastUtil.hideLoading();
      ToastUtil.error(e is DioException ? (e.message ?? '修改失败') : '修改失败');
    }
  }

  Future<void> logout() async {
    Get.dialog(
      AlertDialog(
        title: Text('退出登录'),
        content: Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              userController.logout();
              Get.offAllNamed(AppRoutes.login);
            },
            child: Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
