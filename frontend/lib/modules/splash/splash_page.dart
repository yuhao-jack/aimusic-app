import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/splash/splash_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';

/// 启动页 - 带流畅动画的品牌展示
/// 增强版：更精致的辉光效果、光圈粒子感
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _bgGlowController;
  late Animation<double> _bgGlowAnimation;

  // Additional controllers for enhanced effects
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    // 确保控制器初始化
    Get.find<SplashController>();

    // Logo 弹性放大动画
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // 文字淡入动画
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // 背景呼吸光效
    _bgGlowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _bgGlowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _bgGlowController, curve: Curves.easeInOut),
    );

    // 脉冲辉光
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 光圈旋转
    _ringController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _ringAnimation = Tween<double>(begin: 0.0, end: 2.0 * 3.14159).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );

    // 启动动画序列
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _fadeController.forward();
    });
    _bgGlowController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _ringController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _bgGlowController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgGlowAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 2.8 - _bgGlowAnimation.value * 0.6,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.12),
                  AppTheme.surface1,
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // 装饰性背景光圈 - 更丰富
            ..._buildBackgroundGlows(),

            // 光圈环
            ..._buildOrbitalRings(),

            // 主要内容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 28),
                  _buildTitleText(),
                  const SizedBox(height: 80),
                  _buildLoadingIndicator(),
                ],
              ),
            ),

            // 底部版本号
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: _buildVersionText(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundGlows() {
    return [
      // Primary glow - top right (靛蓝)
      Positioned(
        top: -120,
        right: -80,
        child: AnimatedBuilder(
          animation: _bgGlowAnimation,
          builder: (context, _) {
            return Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.brandIndigo.withOpacity(0.15),
                    AppTheme.brandPurple.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
      ),
      // Secondary glow - bottom left (紫色)
      Positioned(
        bottom: -100,
        left: -60,
        child: AnimatedBuilder(
          animation: _bgGlowAnimation,
          builder: (context, _) {
            return Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.brandPurple.withOpacity(0.12),
                    AppTheme.brandIndigo.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
      ),
      // Center pulsing glow (靛蓝)
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) {
            return Center(
              child: Container(
                width: 400 * _pulseAnimation.value,
                height: 400 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.brandIndigo.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildOrbitalRings() {
    return [
      // Outer orbit ring (靛蓝)
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: AnimatedBuilder(
          animation: _ringAnimation,
          builder: (context, _) {
            return CustomPaint(
              painter: _RingPainter(
                progress: _ringAnimation.value,
                color1: AppTheme.brandIndigo.withOpacity(0.2),
                color2: AppTheme.brandPurple.withOpacity(0.12),
                radius: 0.3,
              ),
            );
          },
        ),
      ),
      // Inner orbit ring (紫)
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: AnimatedBuilder(
          animation: _ringAnimation,
          builder: (context, _) {
            return CustomPaint(
              painter: _RingPainter(
                progress: _ringAnimation.value + 1.0,
                color1: AppTheme.brandPurple.withOpacity(0.15),
                color2: AppTheme.brandIndigo.withOpacity(0.08),
                radius: 0.22,
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: AppTheme.secondaryColor.withOpacity(0.2),
              blurRadius: 50,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.music_note_rounded,
                size: 72,
                color: AppTheme.textWhite,
              ),
            ),
            // Decorative floating notes
            Positioned(
              top: 24,
              right: 24,
              child: Icon(
                Icons.music_note_rounded,
                size: 24,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Positioned(
              bottom: 28,
              left: 24,
              child: Icon(
                Icons.music_note_outlined,
                size: 20,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleText() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          const Text(
            'AI Music',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
              ],
            ).createShader(bounds),
            child: const Text(
              '让AI为你创作音乐',
              style: TextStyle(
                color: AppTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            child: CircularProgressIndicator(
              color: AppTheme.brandIndigo,
              strokeWidth: 3,
              backgroundColor: AppTheme.surface3,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onLongPress: () => _showTestMenu(context),
            child: const Text(
              '正在准备体验...',
              style: TextStyle(
                color: AppTheme.textLightGray,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionText() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: const Center(
        child: Text(
          'v1.0.0',
          style: TextStyle(
            color: AppTheme.textDarkGray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===== 测试菜单 =====
  void _showTestMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 测试模式',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _testButton('首页', AppRoutes.home),
                _testButton('创作', AppRoutes.create),
                _testButton('搜索', AppRoutes.search),
                _testButton('播放器', AppRoutes.player),
                _testButton('社区', AppRoutes.together),
                _testButton('个人', AppRoutes.profile),
                _testButton('登录', AppRoutes.login),
                _testButton('注册', AppRoutes.register),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _testButton(String label, String route) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        Get.offAllNamed(route);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surface3,
        foregroundColor: AppTheme.textWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label,
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}

/// Custom painter for orbital ring effect
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;
  final double radius;

  _RingPainter({
    required this.progress,
    required this.color1,
    required this.color2,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius = size.shortestSide * radius;

    // Draw ring
    final ringPaint = Paint()
      ..color = color1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, ringRadius, ringPaint);

    // Draw orbiting dot
    final dotX = center.dx + ringRadius * cos(progress);
    final dotY = center.dy + ringRadius * sin(progress);

    final dotPaint = Paint()
      ..shader = RadialGradient(
        colors: [color1, color2],
      ).createShader(Rect.fromCircle(center: Offset(dotX, dotY), radius: 4));

    canvas.drawCircle(Offset(dotX, dotY), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
