import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/routes/app_pages.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/theme/theme_provider.dart';
import 'package:aimusic_app/theme/theme_bridge.dart';
import 'package:aimusic_app/utils/storage_util.dart';
import 'package:aimusic_app/utils/http_util.dart';
import 'package:aimusic_app/widgets/network_banner.dart';
// Services
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/services/auth_service.dart';
import 'package:aimusic_app/services/oauth_service.dart';
import 'package:aimusic_app/services/user_service.dart';
import 'package:aimusic_app/services/music_service.dart';
import 'package:aimusic_app/services/ai_service.dart';
import 'package:aimusic_app/services/playlist_service.dart';
import 'package:aimusic_app/services/post_service.dart';
import 'package:aimusic_app/services/membership_service.dart';
import 'package:aimusic_app/global/user_controller.dart';
// Controllers
import 'package:aimusic_app/modules/create/create_controller.dart';
import 'package:aimusic_app/modules/profile/profile_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式（沉浸式）
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surface1,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // 允许全屏沉浸模式
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // 初始化本地存储
  await StorageUtil.init();

  // 注册全局服务 - 按依赖顺序
  Get.put(ApiService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(OAuthService(), permanent: true);
  Get.put(UserService(), permanent: true);
  Get.put(MusicService(), permanent: true);
  Get.put(AIService(), permanent: true);
  Get.put(PlaylistService(), permanent: true);
  Get.put(PostService(), permanent: true);
  Get.put(MembershipService(), permanent: true);
  Get.put(TrackingService(), permanent: true);

  // 全局控制器
  Get.put(UserController(), permanent: true);
  Get.put(CreateController(), permanent: true);
  Get.put(ProfileController(), permanent: true);

  // 初始化主题系统
  await ThemeBridge.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 响应式包裹 GetMaterialApp，使得主题切换时自动刷新
    return Obx(() {
      final themeProvider = ThemeProvider.to;

      return GetMaterialApp(
        title: '音浪AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeBridge.lightTheme,
        darkTheme: ThemeBridge.darkTheme,
        themeMode: themeProvider.flutterThemeMode,
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,

        // ========== 丝滑过渡配置 ==========

        // 默认页面过渡动画 - 用自定义动画替代
        defaultTransition: Transition.cupertino,
        transitionDuration: const Duration(milliseconds: 350),

        // 弹出式页面（如对话框）使用缩放动画
        popGesture: true, // iOS 侧滑返回

        // 自定义页面构建器 - 全局处理页面切换
        builder: (context, child) {
          // 添加全局的滑动返回手势 + 网络状态 Banner
          return GestureDetector(
            onTap: () {
              // 点击空白区域关闭键盘
              FocusScope.of(context).unfocus();
            },
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              child: Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  // 全局网络状态 Banner
                  Obx(() => NetworkBanner(
                    isConnected: NetworkStatus().isConnected.value,
                    onNetworkRestored: () {
                      debugPrint('网络已恢复，自动重试失败请求');
                      HttpUtil().flushRetryQueue();
                    },
                  )),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
