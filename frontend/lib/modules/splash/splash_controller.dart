import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/global/user_controller.dart';
import 'package:aimusic_app/modules/onboarding/onboarding_controller.dart';
import 'package:aimusic_app/routes/app_routes.dart';

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
}
