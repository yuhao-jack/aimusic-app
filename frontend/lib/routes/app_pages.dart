import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/modules/login/login_binding.dart';
import 'package:aimusic_app/modules/login/login_page.dart';
import 'package:aimusic_app/modules/register/register_binding.dart';
import 'package:aimusic_app/modules/register/register_page.dart';
import 'package:aimusic_app/modules/forget_password/forget_password_binding.dart';
import 'package:aimusic_app/modules/forget_password/forget_password_page.dart';
import 'package:aimusic_app/modules/splash/splash_binding.dart';
import 'package:aimusic_app/modules/splash/splash_page.dart';
import 'package:aimusic_app/modules/onboarding/onboarding_binding.dart';
import 'package:aimusic_app/modules/onboarding/onboarding_page.dart';
import 'package:aimusic_app/modules/home/home_binding.dart';
import 'package:aimusic_app/modules/home/home_page.dart';
import 'package:aimusic_app/modules/search/search_binding.dart';
import 'package:aimusic_app/modules/search/search_page.dart';
import 'package:aimusic_app/modules/music/music_detail_binding.dart';
import 'package:aimusic_app/modules/music/music_detail_page.dart';
import 'package:aimusic_app/modules/create/create_binding.dart';
import 'package:aimusic_app/modules/create/create_page.dart';
import 'package:aimusic_app/modules/create/lyric_create_binding.dart';
import 'package:aimusic_app/modules/create/lyric_create_page.dart';
import 'package:aimusic_app/modules/create/song_create_binding.dart';
import 'package:aimusic_app/modules/create/song_create_page.dart';
import 'package:aimusic_app/modules/create/task_progress_binding.dart';
import 'package:aimusic_app/modules/create/task_progress_page.dart';
import 'package:aimusic_app/modules/profile/profile_binding.dart';
import 'package:aimusic_app/modules/profile/profile_page.dart';
import 'package:aimusic_app/modules/profile/my_works_binding.dart';
import 'package:aimusic_app/modules/profile/my_works_page.dart';
import 'package:aimusic_app/modules/profile/my_likes_binding.dart';
import 'package:aimusic_app/modules/profile/my_likes_page.dart';
import 'package:aimusic_app/modules/history/history_binding.dart';
import 'package:aimusic_app/modules/history/history_page.dart';
import 'package:aimusic_app/modules/voice_clone/voice_clone_binding.dart';
import 'package:aimusic_app/modules/voice_clone/voice_clone_page.dart';
import 'package:aimusic_app/modules/create/lyric_optimize_binding.dart';
import 'package:aimusic_app/modules/create/lyric_optimize_page.dart';
import 'package:aimusic_app/modules/challenge/challenge_binding.dart';
import 'package:aimusic_app/modules/challenge/challenge_page.dart';
import 'package:aimusic_app/modules/playlist/playlist_binding.dart';
import 'package:aimusic_app/modules/playlist/playlist_page.dart';
import 'package:aimusic_app/modules/profile/settings_binding.dart';
import 'package:aimusic_app/modules/profile/settings_page.dart';
import 'package:aimusic_app/modules/player/player_binding.dart';
import 'package:aimusic_app/modules/player/player_page.dart';
import 'package:aimusic_app/modules/together/together_binding.dart';
import 'package:aimusic_app/modules/together/together_page.dart';
import 'package:aimusic_app/modules/post/post_binding.dart';
import 'package:aimusic_app/modules/post/post_page.dart';
import 'package:aimusic_app/modules/post/create_post_page.dart';
import 'package:aimusic_app/modules/creator/creator_detail_page.dart';
import 'package:aimusic_app/modules/creator/creator_binding.dart';
import 'package:aimusic_app/modules/follow/follow_binding.dart';
import 'package:aimusic_app/modules/follow/follow_page.dart';
import 'package:aimusic_app/modules/notification/notification_binding.dart';
import 'package:aimusic_app/modules/notification/notification_page.dart';
import 'package:aimusic_app/modules/fm/fm_binding.dart';
import 'package:aimusic_app/modules/fm/fm_page.dart';
import 'package:aimusic_app/modules/membership/membership_binding.dart';
import 'package:aimusic_app/modules/membership/membership_page.dart';
import 'package:aimusic_app/modules/invite/invite_page.dart';
import 'package:aimusic_app/modules/tasks/daily_tasks_page.dart';
import 'package:aimusic_app/modules/shop/points_shop_page.dart';
import 'package:aimusic_app/modules/report/listening_report_binding.dart';
import 'package:aimusic_app/modules/report/listening_report_page.dart';
import 'package:aimusic_app/modules/profile/public_profile_binding.dart';
import 'package:aimusic_app/modules/profile/public_profile_page.dart';
import 'package:aimusic_app/modules/ai_chat/ai_chat_binding.dart';
import 'package:aimusic_app/modules/ai_chat/ai_chat_page.dart';

class AppPages {
  /// 自定义共享元素过渡路由 — 用于播放器详情页等关键页面
  static GetPage _buildHeroRoute({
    required String name,
    required Widget Function() page,
    Bindings? binding,
    String? heroTag,
  }) {
    return GetPage(
      name: name,
      page: page,
      binding: binding,
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      customTransition: _HeroTransition(),
    );
  }

  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => SplashPage(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 600),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => OnboardingPage(),
      binding: OnboardingBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginPage(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => RegisterPage(),
      binding: RegisterBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.forgetPassword,
      page: () => ForgetPasswordPage(),
      binding: ForgetPasswordBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => HomePage(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => SearchPage(),
      binding: SearchBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    ),
    // 播放器详情页 — 共享元素过渡
    _buildHeroRoute(
      name: AppRoutes.player,
      page: () => PlayerPage(),
      binding: PlayerBinding(),
      heroTag: 'player_cover',
    ),
    _buildHeroRoute(
      name: AppRoutes.musicDetail,
      page: () => MusicDetailPage(),
      binding: MusicDetailBinding(),
      heroTag: 'music_cover',
    ),
    GetPage(
      name: AppRoutes.create,
      page: () => CreatePage(),
      binding: CreateBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => ProfilePage(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.together,
      page: () => TogetherPage(),
      binding: TogetherBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.post,
      page: () => PostPage(),
      binding: PostBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.createPost,
      page: () => CreatePostPage(),
      binding: CreatePostBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.createLyric,
      page: () => LyricCreatePage(),
      binding: LyricCreateBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.createSong,
      page: () => SongCreatePage(),
      binding: SongCreateBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.taskProgress,
      page: () => TaskProgressPage(),
      binding: TaskProgressBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: AppRoutes.myWorks,
      page: () => MyWorksPage(),
      binding: MyWorksBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.myLikes,
      page: () => MyLikesPage(),
      binding: MyLikesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => HistoryPage(),
      binding: HistoryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.voiceClone,
      page: () => VoiceClonePage(),
      binding: VoiceCloneBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.lyricOptimize,
      page: () => LyricOptimizePage(),
      binding: LyricOptimizeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.challenge,
      page: () => ChallengePage(),
      binding: ChallengeBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.playlist,
      page: () => PlaylistPage(),
      binding: PlaylistBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => SettingsPage(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.creatorDetail,
      page: () => CreatorDetailPage(),
      binding: CreatorBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.follow,
      page: () => FollowPage(),
      binding: FollowBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.notification,
      page: () => NotificationPage(),
      binding: NotificationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.fm,
      page: () => FmPage(),
      binding: FmBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: AppRoutes.membership,
      page: () => MembershipPage(),
      binding: MembershipBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.listeningReport,
      page: () => ListeningReportPage(),
      binding: ListeningReportBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.invite,
      page: () => InvitePage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.dailyTasks,
      page: () => DailyTasksPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.pointsShop,
      page: () => PointsShopPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.publicProfile,
      page: () => PublicProfilePage(),
      binding: PublicProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.aiChat,
      page: () => AiChatPage(),
      binding: AiChatBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    ),
  ];
}

/// 共享元素过渡动画 — 播放器/详情页等关键页面使用
class _HeroTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 淡入 + 轻微上滑
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: curve ?? Curves.easeOutCubic,
    );
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(fadeAnimation);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}
