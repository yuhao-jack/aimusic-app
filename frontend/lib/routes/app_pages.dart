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
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: AppRoutes.forgetPassword,
      page: () => const ForgetPasswordPage(),
      binding: ForgetPasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: AppRoutes.create,
      page: () => const CreatePage(),
      binding: CreateBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.player,
      page: () => const PlayerPage(),
      binding: PlayerBinding(),
    ),
    GetPage(
      name: AppRoutes.together,
      page: () => TogetherPage(),
      binding: TogetherBinding(),
    ),
    GetPage(
      name: AppRoutes.post,
      page: () => const PostPage(),
      binding: PostBinding(),
    ),
    GetPage(
      name: AppRoutes.createPost,
      page: () => const CreatePostPage(),
      binding: CreatePostBinding(),
    ),
    GetPage(
      name: AppRoutes.musicDetail,
      page: () => const MusicDetailPage(),
      binding: MusicDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.createLyric,
      page: () => const LyricCreatePage(),
      binding: LyricCreateBinding(),
    ),
    GetPage(
      name: AppRoutes.createSong,
      page: () => const SongCreatePage(),
      binding: SongCreateBinding(),
    ),
    GetPage(
      name: AppRoutes.taskProgress,
      page: () => const TaskProgressPage(),
      binding: TaskProgressBinding(),
    ),
    GetPage(
      name: AppRoutes.myWorks,
      page: () => const MyWorksPage(),
      binding: MyWorksBinding(),
    ),
    GetPage(
      name: AppRoutes.myLikes,
      page: () => const MyLikesPage(),
      binding: MyLikesBinding(),
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => const HistoryPage(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.voiceClone,
      page: () => const VoiceClonePage(),
      binding: VoiceCloneBinding(),
    ),
    GetPage(
      name: AppRoutes.lyricOptimize,
      page: () => const LyricOptimizePage(),
      binding: LyricOptimizeBinding(),
    ),
    GetPage(
      name: AppRoutes.challenge,
      page: () => const ChallengePage(),
      binding: ChallengeBinding(),
    ),
    GetPage(
      name: AppRoutes.playlist,
      page: () => const PlaylistPage(),
      binding: PlaylistBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.creatorDetail,
      page: () => const CreatorDetailPage(),
      binding: CreatorBinding(),
    ),
    GetPage(
      name: AppRoutes.follow,
      page: () => const FollowPage(),
      binding: FollowBinding(),
    ),
    GetPage(
      name: AppRoutes.notification,
      page: () => const NotificationPage(),
      binding: NotificationBinding(),
    ),
    GetPage(
      name: AppRoutes.fm,
      page: () => const FmPage(),
      binding: FmBinding(),
    ),
    GetPage(
      name: AppRoutes.membership,
      page: () => const MembershipPage(),
      binding: MembershipBinding(),
    ),
    GetPage(
      name: AppRoutes.membership,
      page: () => const MembershipPage(),
      binding: MembershipBinding(),
    ),
    GetPage(
      name: AppRoutes.listeningReport,
      page: () => const ListeningReportPage(),
      binding: ListeningReportBinding(),
    ),
    GetPage(
      name: AppRoutes.membership,
      page: () => const MembershipPage(),
      binding: MembershipBinding(),
    ),
    GetPage(
      name: AppRoutes.invite,
      page: () => const InvitePage(),
    ),
    GetPage(
      name: AppRoutes.dailyTasks,
      page: () => const DailyTasksPage(),
    ),
    GetPage(
      name: AppRoutes.pointsShop,
      page: () => const PointsShopPage(),
    ),
    GetPage(
      name: AppRoutes.publicProfile,
      page: () => const PublicProfilePage(),
      binding: PublicProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.aiChat,
      page: () => const AiChatPage(),
      binding: AiChatBinding(),
    ),
  ];
}
