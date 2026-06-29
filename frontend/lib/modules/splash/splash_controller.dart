import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:aimusic_app/global/user_controller.dart';
import 'package:aimusic_app/modules/onboarding/onboarding_controller.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/services/api_service.dart';

class SplashController extends GetxController {
  late final UserController _userController;

  @override
  void onInit() {
    super.onInit();
    debugPrint('SplashController: onInit 被调用');
    try {
      _userController = Get.find<UserController>();
      debugPrint('SplashController: UserController 获取成功');
      // 确保在下一帧执行，避免初始化竞争
      Future.microtask(() => _initApp());
    } catch (e) {
      debugPrint('SplashController: 获取 UserController 失败: $e');
      // 即使失败也尝试跳转
      Future.microtask(() => _initApp());
    }
  }

  Future<void> _initApp() async {
    try {
      debugPrint('SplashController: 开始初始化...');
      
      // 安全获取登录状态
      bool isLogin = false;
      try {
        isLogin = _userController.isLogin;
      } catch (e) {
        debugPrint('SplashController: 获取登录状态失败: $e');
      }
      
      debugPrint('SplashController: 登录状态 = $isLogin');
      
      // 检查版本更新
      await _checkVersionUpdate();
      
      // 模拟初始化过程，后续可以加权限申请、资源加载等
      await Future.delayed(const Duration(seconds: 2));
      
      debugPrint('SplashController: 准备跳转页面...');
      
      // 检查是否已完成新用户引导
      final onboardingCompleted = OnboardingController.isOnboardingCompleted();
      if (!onboardingCompleted) {
        debugPrint('SplashController: 跳转到引导页');
        Get.offAllNamed(AppRoutes.onboarding);
        return;
      }

      // 判断是否登录
      if (isLogin) {
        debugPrint('SplashController: 跳转到首页');
        Get.offAllNamed(AppRoutes.home);
      } else {
        debugPrint('SplashController: 跳转到登录页');
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e, stackTrace) {
      debugPrint('Splash初始化错误: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      // 如果出错，强制跳转到登录页
      try {
        Get.offAllNamed(AppRoutes.login);
      } catch (e2) {
        debugPrint('跳转失败: $e2');
      }
    }
  }

  /// 检查版本更新
  Future<void> _checkVersionUpdate() async {
    try {
      final api = Get.find<ApiService>();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 1;

      final response = await api.get('/system/version-check', queryParameters: {
        'platform': GetPlatform.isIOS ? 'ios' : 'android',
        'version_code': currentVersion,
      });

      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        final needUpdate = data['need_update'] ?? false;
        final forceUpdate = data['force_update'] ?? false;

        if (needUpdate) {
          final versionName = data['version_name'] ?? '';
          final changelog = data['changelog'] ?? '';
          final updateUrl = data['update_url'] ?? '';

          // 显示更新弹窗
          await _showUpdateDialog(
            versionName: versionName,
            changelog: changelog,
            updateUrl: updateUrl,
            forceUpdate: forceUpdate,
          );
        }
      }
    } catch (e) {
      debugPrint('版本检查失败: $e');
    }
  }

  /// 显示更新弹窗
  Future<void> _showUpdateDialog({
    required String versionName,
    required String changelog,
    required String updateUrl,
    required bool forceUpdate,
  }) async {
    await Get.dialog(
      AlertDialog(
        title: Text('发现新版本 v$versionName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (changelog.isNotEmpty) ...[
              const Text('更新内容:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(changelog),
              const SizedBox(height: 16),
            ],
            if (forceUpdate)
              const Text('此为强制更新，必须升级后才能使用', 
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('稍后再说'),
            ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // 打开应用商店或下载链接
              if (updateUrl.isNotEmpty) {
                // url_launcher.launchUrl(Uri.parse(updateUrl));
              }
            },
            child: const Text('立即更新'),
          ),
        ],
      ),
      barrierDismissible: !forceUpdate,
    );
  }
}
