import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/create/create_controller.dart';
import 'package:aimusic_app/modules/membership/membership_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

class CreatePage extends GetView<CreateController> {
  CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.brandIndigo,
          backgroundColor: AppTheme.surface2,
          onRefresh: () => controller.refreshWorks(),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Top Header =====
              _buildHeader(),
              SizedBox(height: 24),

              // ===== Hero Entry Card =====
              FadeInWidget(
                delayMs: 80,
                child: _buildHeroCard(),
              ),
              SizedBox(height: 24),

              // ===== Feature Cards =====
              StaggeredList(
                startDelay: 160,
                staggerDelay: 80,
                children: [
                  _buildFeatureRow(
                    features: [
                      _FeatureData(
                        icon: Icons.edit_rounded,
                        title: '生成歌词',
                        subtitle: '输入关键词，获取完整歌词',
                        route: AppRoutes.createLyric,
                        badge: _FeatureBadge.ai,
                        iconGradient: AppTheme.coolGradient,
                        iconGlowColor: AppTheme.brandIndigo,
                      ),
                      _FeatureData(
                        icon: Icons.auto_fix_high_rounded,
                        title: '优化歌词',
                        subtitle: '优化已有歌词，让它更完美',
                        route: AppRoutes.lyricOptimize,
                        badge: _FeatureBadge.ai,
                        iconGradient: AppTheme.coolGradient,
                        iconGlowColor: AppTheme.brandIndigo,
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  _buildFeatureRow(
                    features: [
                      _FeatureData(
                        icon: Icons.music_note_rounded,
                        title: '生成歌曲',
                        subtitle: '从歌词到完整歌曲',
                        route: AppRoutes.createSong,
                        badge: _FeatureBadge.ai,
                        iconGradient: AppTheme.crystalTechGradient,
                        iconGlowColor: AppTheme.brandPurple,
                      ),
                      _FeatureData(
                        icon: Icons.mic_rounded,
                        title: '声音克隆',
                        subtitle: '录制并克隆你的声音',
                        route: AppRoutes.voiceClone,
                        badge: _FeatureBadge.new_,
                        iconGradient: AppTheme.warmGlowGradient,
                        iconGlowColor: AppTheme.brandPink,
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  _buildFeatureRow(
                    features: [
                      _FeatureData(
                        icon: Icons.chat_rounded,
                        title: 'AI 推荐',
                        subtitle: '对话式音乐推荐',
                        route: AppRoutes.aiChat,
                        badge: _FeatureBadge.ai,
                        iconGradient: AppTheme.coolGradient,
                        iconGlowColor: AppTheme.brandCyan,
                      ),
                      _FeatureData(
                        icon: Icons.videocam_rounded,
                        title: '生成 MV',
                        subtitle: '为歌曲生成精彩MV',
                        route: null,
                        badge: _FeatureBadge.new_,
                        iconGradient: AppTheme.warmGlowGradient,
                        iconGlowColor: AppTheme.brandPink,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 32),

              // ===== Recent Creations Header =====
              FadeInWidget(
                delayMs: 160 + 4 * 80 + 60,
                child: Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryToSecondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '最近创作',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.myWorks),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor.withValues(alpha: 0.7),
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        child: Text('查看全部'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14),

              // ===== Recent Creations Scroll =====
              FadeInWidget(
                delayMs: 160 + 4 * 80 + 120,
                child: _buildRecentWorks(),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ===== Header =====
  Widget _buildHeader() {
    // 获取会员控制器（如果已注册）
    final hasMembership = Get.isRegistered<MembershipController>();
    final membershipCtrl = hasMembership ? Get.find<MembershipController>() : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20).copyWith(top: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '创作',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.profile),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.brandIndigo, AppTheme.brandPurple],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandIndigo.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.textWhite,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 配额信息栏
          if (membershipCtrl != null)
            Obx(() => _buildQuotaBar(membershipCtrl)),
        ],
      ),
    );
  }

  // ===== 配额信息栏 =====
  Widget _buildQuotaBar(MembershipController membershipCtrl) {
    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.membership),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface3.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(
              color: AppTheme.brandIndigo.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // AI创作次数
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppTheme.brandIndigo.withValues(alpha: 0.8),
              ),
              SizedBox(width: 6),
              Text(
                '今日AI创作 ${membershipCtrl.aiQuotaText} 次',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSilver,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              // 音币余额
              Icon(
                Icons.monetization_on_rounded,
                size: 16,
                color: AppTheme.brandIndigo.withValues(alpha: 0.8),
              ),
              SizedBox(width: 4),
              Text(
                '音币: ${membershipCtrl.coinBalance}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSilver,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Hero Card ====="开始创作"主要入口卡=====
  Widget _buildHeroCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: _CardHoverWrapper(
        builder: (isHovered) {
          return ElasticButton(
            onTap: () => Get.toNamed(AppRoutes.createSong),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: 160,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryToSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandIndigo.withValues(alpha: isHovered ? 0.45 : 0.3),
                    blurRadius: isHovered ? 28 : 16,
                    offset: Offset(0, isHovered ? 8 : 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Decorative particle-like circles
                  Positioned(
                    top: -20,
                    right: -10,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    right: 40,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 60,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),

                  // Hover shimmer overlay
                  if (isHovered)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.03),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon chip
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: AppTheme.textWhite,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'AI 音乐',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textWhite,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '开始创作',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textWhite,
                            letterSpacing: -0.3,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '用 AI 把你的灵感变成一首歌',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow indicator
                  Positioned(
                    bottom: 18,
                    right: 18,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== Feature Card Row =====
  Widget _buildFeatureRow({required List<_FeatureData> features}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: features.map((f) => Expanded(child: _buildFeatureCard(f))).toList(),
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureData data) {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: _CardHoverWrapper(
        builder: (isHovered) {
          return ElasticButton(
            onTap: data.route != null
                ? () => Get.toNamed(data.route!)
                : () => _showMvGenerateDialog(),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: AppTheme.surface3,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: isHovered
                        ? AppTheme.brandIndigo.withValues(alpha: 0.3)
                        : AppTheme.borderSubtle.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: AppTheme.brandIndigo.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Upper-left gradient glow decoration
                    Positioned(
                      top: -40,
                      left: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              data.iconGlowColor.withValues(alpha: 0.2),
                              data.iconGlowColor.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Hover shimmer
                    if (isHovered)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Content
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon with gradient circular background (48px)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: data.iconGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: data.iconGlowColor.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              data.icon,
                              size: 22,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Spacer(),
                          // Title
                          Text(
                            data.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textWhite,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          // Subtitle
                          Text(
                            data.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSilver,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Badge
                    if (data.badge != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            data.badge!.display,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textWhite,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== Recent Works (Glass Cards, Horizontal Scroll) =====
  Widget _buildRecentWorks() {
    return Obx(() {
      if (controller.works.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: AppTheme.borderSubtle.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.brandIndigo.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.music_off_rounded,
                    size: 24,
                    color: AppTheme.brandIndigo.withValues(alpha: 0.4),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '还没有创作',
                  style: TextStyle(
                    color: AppTheme.textSilver,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '点击上方卡片开始创作',
                  style: TextStyle(
                    color: AppTheme.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.only(left: 20, right: 8),
          itemCount: controller.works.length,
          itemBuilder: (context, index) {
            final work = controller.works[index];
            return _buildWorkGlassCard(work, index);
          },
        ),
      );
    });
  }

  Widget _buildWorkGlassCard(Map<String, dynamic> work, int index) {
    return Padding(
      padding: EdgeInsets.only(right: 14),
      child: _CardHoverWrapper(
        builder: (isHovered) {
          return SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover with glass effect
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                        border: Border.all(
                          color: AppTheme.borderSubtle.withValues(alpha: 0.35),
                          width: 0.5,
                        ),
                        image: work['cover'] != null
                            ? DecorationImage(
                                image: NetworkImage(work['cover']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // Glass overlay
                          if (work['cover'] != null)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.surface1.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Default icon if no cover
                          if (work['cover'] == null)
                            Center(
                              child: Icon(
                                Icons.music_note_rounded,
                                size: 44,
                                color: AppTheme.textDarkGray,
                              ),
                            ),

                          // Play overlay on hover
                          if (isHovered)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusComfortable),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                      gradient: AppTheme.crystalTechGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.brandIndigo.withValues(alpha: 0.35),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      color: AppTheme.textWhite,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Title
                Text(
                  work['title'] ?? '未命名',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),
                // Status with dot indicator
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(work['status'] ?? '草稿'),
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      work['status'] ?? '草稿',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textDim,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case '完成':
      case 'done':
        return Color(0xFF34D399);
      case '生成中':
      case 'processing':
        return AppTheme.brandIndigo;
      case '草稿':
      case 'draft':
        return AppTheme.textDarkGray;
      default:
        return AppTheme.textDarkGray;
    }
  }

  /// MV生成表单弹窗
  void _showMvGenerateDialog() {
    // 重置MV弹窗状态
    controller.mvSelectedSong.value = null;
    controller.mvSelectedStyle.value = '科幻';
    controller.clearMvMedia();
    // MV风格列表
    final mvStyles = ['科幻', '动漫', '写实', '抽象'];

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(
            color: AppTheme.borderSubtle.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.warmGlowGradient,
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      size: 20,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '生成 MV',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close_rounded,
                        color: AppTheme.textSilver, size: 20),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // 选择歌曲
              Text(
                '选择歌曲',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSilver,
                ),
              ),
              SizedBox(height: 8),
              Obx(() {
                final works = controller.works;
                if (works.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusComfortable),
                      border: Border.all(
                        color: AppTheme.borderSubtle.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '暂无作品，请先创作歌曲',
                        style: TextStyle(
                            color: AppTheme.textDim, fontSize: 13),
                      ),
                    ),
                  );
                }
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusComfortable),
                    border: Border.all(
                      color: AppTheme.borderSubtle.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: controller.mvSelectedSong.value,
                      hint: Text(
                        '请选择一首歌曲',
                        style:
                            TextStyle(color: AppTheme.textDim, fontSize: 13),
                      ),
                      isExpanded: true,
                      dropdownColor: AppTheme.surface3,
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textSilver),
                      items: works.asMap().entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(
                            entry.value['title'] ?? '未命名',
                            style: TextStyle(
                                color: AppTheme.textWhite, fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => controller.mvSelectedSong.value = value,
                    ),
                  ),
                );
              }),
              SizedBox(height: 20),

              // 选择MV风格
              Text(
                'MV 风格',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSilver,
                ),
              ),
              SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: mvStyles.map((style) {
                      final isSelected = controller.mvSelectedStyle.value == style;
                      return GestureDetector(
                        onTap: () => controller.mvSelectedStyle.value = style,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.brandIndigo.withValues(alpha: 0.15)
                                : AppTheme.surface2,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusFullPill),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.brandIndigo.withValues(alpha: 0.5)
                                  : AppTheme.borderSubtle
                                      .withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Text(
                            style,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppTheme.brandIndigo
                                  : AppTheme.textSilver,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
              SizedBox(height: 20),

              // 上传素材区域
              Text(
                '上传素材（可选）',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSilver,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '支持图片和视频，将用于MV画面生成',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textDim,
                ),
              ),
              SizedBox(height: 8),
              Obx(() {
                final files = controller.mvMediaFiles;
                return Column(
                  children: [
                    // 已选素材预览
                    if (files.isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: files.length,
                          separatorBuilder: (_, __) => SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final file = files[index];
                            final isVideo = file.path.endsWith('.mp4') ||
                                file.path.endsWith('.mov') ||
                                file.path.endsWith('.avi');
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium),
                                  child: isVideo
                                      ? Container(
                                          width: 80,
                                          height: 80,
                                          color: AppTheme.surface2,
                                          child: Center(
                                            child: Icon(
                                              Icons.videocam_rounded,
                                              color: AppTheme.textSilver,
                                              size: 28,
                                            ),
                                          ),
                                        )
                                      : Image.file(
                                          File(file.path),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                // 删除按钮
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () =>
                                        controller.removeMvMedia(index),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: AppTheme.textWhite,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (files.isNotEmpty) SizedBox(height: 10),
                    // 上传按钮
                    GestureDetector(
                      onTap: () => controller.pickMvMedia(),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusComfortable),
                          border: Border.all(
                            color: AppTheme.borderSubtle.withValues(alpha: 0.4),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 18,
                              color: AppTheme.brandIndigo.withValues(alpha: 0.7),
                            ),
                            SizedBox(width: 8),
                            Text(
                              files.isEmpty ? '选择图片或视频' : '继续添加素材',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.brandIndigo.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
              SizedBox(height: 28),

              // 生成按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final mediaCount = controller.mvMediaFiles.length;
                    Get.back();
                    // 显示提交成功提示
                    Get.snackbar(
                      'MV 生成',
                      mediaCount > 0
                          ? 'MV生成任务已提交（已附加$mediaCount个素材），请在任务中心查看进度'
                          : 'MV生成任务已提交，请在任务中心查看进度',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppTheme.brandIndigo,
                      colorText: AppTheme.textWhite,
                      margin: EdgeInsets.all(16),
                      borderRadius: AppTheme.radiusComfortable,
                      duration: Duration(seconds: 3),
                      icon: Icon(Icons.check_circle_rounded,
                          color: AppTheme.textWhite),
                    );
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
                    '开始生成',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// Data classes for feature cards
// ====================================================================
enum _FeatureBadge {
  ai,
  new_;

  String get display {
    switch (this) {
      case _FeatureBadge.ai:
        return 'AI';
      case _FeatureBadge.new_:
        return 'NEW';
    }
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;
  final _FeatureBadge? badge;
  final LinearGradient iconGradient;
  final Color iconGlowColor;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
    this.badge,
    required this.iconGradient,
    required this.iconGlowColor,
  });
}

// ====================================================================
// Hover Wrapper (retained with same API)
// ====================================================================
class _CardHoverWrapper extends StatefulWidget {
  final Widget Function(bool isHovered) builder;

  _CardHoverWrapper({required this.builder});

  @override
  State<_CardHoverWrapper> createState() => _CardHoverWrapperState();
}

class _CardHoverWrapperState extends State<_CardHoverWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.builder(_isHovered),
    );
  }
}
