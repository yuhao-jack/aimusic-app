import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/onboarding/onboarding_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

/// 新用户引导页 — 3页引导流程
/// 第1页：欢迎使用音浪AI
/// 第2页：选择音乐风格偏好
/// 第3页：选择心情偏好
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final controller = Get.find<OnboardingController>();
  late final PageController _pageController;

  // 音符浮动动画
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // 背景呼吸光效
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 音符上下浮动
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatController.repeat(reverse: true);

    // 背景呼吸光效
    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      body: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 2.0,
                colors: [
                  AppTheme.brandIndigo
                      .withValues(alpha: 0.08 * _glowAnimation.value),
                  AppTheme.surface1,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // 顶部跳过按钮
              _buildSkipButton(),
              // 页面内容
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    controller.currentPage.value = index;
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildGenrePage(),
                    _buildMoodPage(),
                  ],
                ),
              ),
              // 底部指示器和按钮
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部跳过按钮
  Widget _buildSkipButton() {
    return Obx(() {
      if (controller.currentPage.value >= 2) return const SizedBox(height: 48);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => controller.completeOnboarding(),
              child: const Text(
                '跳过',
                style: TextStyle(
                  color: AppTheme.textSilver,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 第1页 — 欢迎使用音浪AI
  Widget _buildWelcomePage() {
    return FadeInWidget(
      duration: const Duration(milliseconds: 600),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 动画音符图标
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryToSecondary,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandIndigo.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: 60,
                      color: AppTheme.textWhite,
                    ),
                    Positioned(
                      top: 18,
                      right: 22,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 20,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            // 标题
            FadeInWidget(
              delayMs: 200,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.brandIndigo, AppTheme.brandPurple],
                ).createShader(bounds),
                child: const Text(
                  '欢迎使用音浪AI',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 副标题
            const FadeInWidget(
              delayMs: 400,
              child: Text(
                '让AI为你创作音乐',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textSilver,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const FadeInWidget(
              delayMs: 600,
              child: Text(
                '用科技的力量，释放你的音乐灵感',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDarkGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 第2页 — 选择音乐风格偏好
  Widget _buildGenrePage() {
    return FadeInWidget(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FadeInWidget(
              delayMs: 100,
              child: Text(
                '🎶',
                style: TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 20),
            const FadeInWidget(
              delayMs: 200,
              child: Text(
                '选择你喜欢的音乐风格',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const FadeInWidget(
              delayMs: 300,
              child: Text(
                '我们会根据你的偏好推荐更合适的内容',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSilver,
                ),
              ),
            ),
            const SizedBox(height: 36),
            // 风格选择网格
            FadeInWidget(
              delayMs: 400,
              child: Obx(() => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: OnboardingController.genres.map((genre) {
                      final isSelected =
                          controller.selectedGenres.contains(genre['label']);
                      return _buildChoiceChip(
                        label: genre['label'],
                        icon: genre['icon'],
                        isSelected: isSelected,
                        onTap: () => controller.toggleGenre(genre['label']),
                      );
                    }).toList(),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  /// 第3页 — 选择心情偏好
  Widget _buildMoodPage() {
    return FadeInWidget(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FadeInWidget(
              delayMs: 100,
              child: Text(
                '💫',
                style: TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 20),
            const FadeInWidget(
              delayMs: 200,
              child: Text(
                '你现在的心情是？',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const FadeInWidget(
              delayMs: 300,
              child: Text(
                '选择你常听的心情类型',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSilver,
                ),
              ),
            ),
            const SizedBox(height: 36),
            // 心情选择网格
            FadeInWidget(
              delayMs: 400,
              child: Obx(() => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: OnboardingController.moods.map((mood) {
                      final isSelected =
                          controller.selectedMoods.contains(mood['label']);
                      return _buildChoiceChip(
                        label: mood['label'],
                        icon: mood['icon'],
                        isSelected: isSelected,
                        onTap: () => controller.toggleMood(mood['label']),
                      );
                    }).toList(),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  /// 通用选择 Chip 组件
  Widget _buildChoiceChip({
    required String label,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandIndigo.withValues(alpha: 0.15)
              : AppTheme.surface3,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected
                ? AppTheme.brandIndigo.withValues(alpha: 0.6)
                : AppTheme.borderSubtle,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? AppTheme.textWhite : AppTheme.textSilver,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 底部指示器和按钮
  Widget _buildBottomBar() {
    return Obx(() {
      final page = controller.currentPage.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          children: [
            // 页面指示器
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = index == page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.brandIndigo
                        : AppTheme.brandIndigo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // 操作按钮
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (page < 2) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  } else {
                    controller.completeOnboarding();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandIndigo,
                  foregroundColor: AppTheme.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFullPill),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  page < 2 ? '下一步' : '开始体验',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
