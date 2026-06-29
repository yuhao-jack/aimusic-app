import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aimusic_app/modules/profile/profile_controller.dart';
import 'package:aimusic_app/modules/diary/music_diary_page.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/modules/membership/membership_controller.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';
import 'package:aimusic_app/modules/profile/listening_stats.dart';

/// 个人中心页
/// 简约 + 毛玻璃 + 科技感 + 紧凑布局重设计
class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: const Text(
          '我的',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // 设置按钮 - 小icon不抢眼，药丸形
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.settings),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface3.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  border: Border.all(
                    color: AppTheme.brandIndigo.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: AppTheme.textSilver,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '设置',
                      style: TextStyle(
                        color: AppTheme.textSilver,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.brandIndigo,
        backgroundColor: AppTheme.surface2,
        onRefresh: () => controller.loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Obx(() {
            if (!controller.isLogin) return _buildNotLoginView();
            return _buildLoginView();
          }),
        ),
      ),
    );
  }

  // ===== 个人中心骨架屏 =====
  Widget _buildProfileShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        // 用户头像+昵称占位
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const ShimmerLoading(width: 70, height: 70, borderRadius: 35),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoading(width: 120, height: 20),
                    const SizedBox(height: 8),
                    const ShimmerLoading(width: 160, height: 13),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 统计行占位
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerLoading(
            width: double.infinity,
            height: 64,
            borderRadius: AppTheme.radiusComfortable,
          ),
        ),
        const SizedBox(height: 20),
        // 成就区域占位
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerLoading(width: 60, height: 16),
              const SizedBox(height: 12),
              ShimmerLoading(
                width: double.infinity,
                height: 100,
                borderRadius: AppTheme.radiusComfortable,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Tab 占位
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: const ShimmerLoading(width: double.infinity, height: 36),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 列表占位
        ...List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: ShimmerLoading(
              width: double.infinity,
              height: 68,
              borderRadius: AppTheme.radiusComfortable,
            ),
          ),
        ),
      ],
    );
  }

  // ===== Not Logged In =====
  Widget _buildNotLoginView() {
    return Center(
      child: FadeInWidget(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.borderSubtle,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 40,
                color: AppTheme.textDarkGray,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '登录音浪AI',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '登录后管理作品与创作',
              style: TextStyle(
                color: AppTheme.textSilver,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandIndigo,
                  foregroundColor: AppTheme.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFullPill),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text(
                  '立即登录',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Logged In View =====
  Widget _buildLoginView() {
    // 加载中显示骨架屏
    if (controller.isLoading.value) {
      return _buildProfileShimmer();
    }
    final user = controller.userInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        // User Header
        _buildUserHeader(user),
        const SizedBox(height: 20),

        // Stats Row（毛玻璃容器行 - 作品/喜欢/歌单合并）
        _buildStatsRow(user),
        const SizedBox(height: 16),

        // 开通VIP卡片
        _buildVIPCard(user),
        const SizedBox(height: 16),

        // 功能入口（每日任务、积分商城、邀请好友）
        _buildFeatureEntries(),
        const SizedBox(height: 20),

        // 成就徽章区域
        _buildAchievementSection(user),
        const SizedBox(height: 24),

        // Tab Selector（紧凑型，无背景）
        _buildTabSelector(),
        const SizedBox(height: 16),

        // Tab Content
        _buildTabContent(),
        const SizedBox(height: 80),
      ],
    );
  }

  // ===== User Header =====
  Widget _buildUserHeader(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Avatar 70px 圆形，带VIP角标
          _buildAvatarWithBadge(user),
          const SizedBox(width: 14),
          // Name & Bio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['nickname'] ?? '用户',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user['bio'] ?? '这个人很懒，什么都没留下',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSilver,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 签到按钮
          _buildCheckInButton(),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppTheme.surface3,
      child: Icon(
        Icons.person_rounded,
        size: 32,
        color: AppTheme.textSilver.withValues(alpha: 0.6),
      ),
    );
  }

  // 头像 + VIP角标
  Widget _buildAvatarWithBadge(Map<String, dynamic> user) {
    final level = user['vip_level'] ?? 0;
    final isSVIP = level == 2;
    final isVIP = level >= 1;
    final badgeColor = isSVIP ? const Color(0xFFFFD700) : AppTheme.brandIndigo;

    return GestureDetector(
      onTap: () => _pickAvatar(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isVIP
                    ? badgeColor.withValues(alpha: 0.5)
                    : AppTheme.brandIndigo.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isVIP ? badgeColor : AppTheme.brandIndigo).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: user['avatar'] != null
                  ? CachedNetworkImage(
                      imageUrl: user['avatar'],
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _defaultAvatar(),
                    )
                  : _defaultAvatar(),
            ),
          ),
          // VIP/SVIP角标
          if (isVIP)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  border: Border.all(color: AppTheme.surface1, width: 1.5),
                ),
                child: Text(
                  isSVIP ? 'SVIP' : 'VIP',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSVIP ? Colors.black : AppTheme.surface1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _pickAvatar() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: AppTheme.surface3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '更改头像',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPickerOption(
                    Icons.camera_alt_rounded,
                    '拍照',
                    () => _pickFromCamera(),
                  ),
                  _buildPickerOption(
                    Icons.photo_library_rounded,
                    '相册',
                    () => _pickFromGallery(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Icon(icon,
                color: AppTheme.brandIndigo, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                color: AppTheme.textSilver,
                fontSize: 13,
              )),
        ],
      ),
    );
  }

  void _pickFromCamera() async {
    Get.back();
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        controller.uploadAvatar(image.path);
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('拍照失败: $e');
    }
  }

  void _pickFromGallery() async {
    Get.back();
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        controller.uploadAvatar(image.path);
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('选择图片失败: $e');
    }
  }

  // ===== Stats Row（毛玻璃容器） =====
  Widget _buildStatsRow(Map<String, dynamic> user) {
    // 获取音币余额
    int coinBalance = 0;
    if (Get.isRegistered<MembershipController>()) {
      coinBalance = Get.find<MembershipController>().coinBalance;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface3.withValues(alpha: 0.55),
          borderRadius:
              BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: AppTheme.borderSubtle.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              '${user['works_count'] ?? 0}',
              '作品',
            ),
            _buildStatDivider(),
            _buildStatItem(
              '${user['likes_count'] ?? 0}',
              '喜欢',
            ),
            _buildStatDivider(),
            _buildStatItem(
              '${user['playlists_count'] ?? 0}',
              '歌单',
            ),
            _buildStatDivider(),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.membership),
              child: _buildStatItem(
                '$coinBalance',
                '音币',
                valueColor: AppTheme.brandIndigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSilver,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppTheme.borderSubtle.withValues(alpha: 0.4),
    );
  }

  // ===== Tab Selector（紧凑型，无背景色，选中下划线primaryColor） =====
  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTabItem('作品', 0),
          _buildTabItem('喜欢', 1),
          _buildTabItem('歌单', 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedTab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? AppTheme.brandIndigo
                    : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppTheme.textWhite
                    : AppTheme.textSilver,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== Tab Content =====
  Widget _buildTabContent() {
    return Obx(() {
      final tab = controller.selectedTab.value;
      switch (tab) {
        case 0:
          return _buildWorksTab();
        case 1:
          return _buildLikesTab();
        case 2:
          return _buildPlaylistsTab();
        default:
          return const SizedBox.shrink();
      }
    });
  }

  // Works Tab
  Widget _buildWorksTab() {
    final works = controller.myWorks;
    if (works.isEmpty) {
      return _buildEmptyTab(
        Icons.music_note_outlined,
        '还没有作品',
        '开始用AI创作你的第一首歌吧',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: works.map((w) => _buildWorkItem(w)).toList(),
      ),
    );
  }

  Widget _buildWorkItem(Map<String, dynamic> work) {
    return ElasticButton(
      onTap: () => Get.toNamed(AppRoutes.musicDetail,
          arguments: work['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surface3.withValues(alpha: 0.5),
          borderRadius:
              BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: AppTheme.borderSubtle.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Cover with rounded 8
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: work['cover_url'] ?? work['cover'] ?? '',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.surface3,
                  child: const Icon(Icons.music_note,
                      size: 20, color: AppTheme.textDarkGray),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.surface3,
                  child: const Icon(Icons.music_note,
                      size: 20, color: AppTheme.textDarkGray),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    work['title'] ?? '未命名作品',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          size: 13, color: AppTheme.textLightGray),
                      const SizedBox(width: 3),
                      Text(
                        _formatCount(work['play_count'] ?? 0),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLightGray,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.favorite_border_rounded,
                          size: 13, color: AppTheme.textLightGray),
                      const SizedBox(width: 3),
                      Text(
                        _formatCount(work['like_count'] ?? 0),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLightGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppTheme.textDarkGray),
          ],
        ),
      ),
    );
  }

  // Likes Tab
  Widget _buildLikesTab() {
    final likes = controller.likedSongs;
    if (likes.isEmpty) {
      return _buildEmptyTab(
        Icons.favorite_outline_rounded,
        '还没有喜欢的歌曲',
        '去发现你喜欢的音乐吧',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: likes.map((w) => _buildWorkItem(w)).toList(),
      ),
    );
  }

  // Playlists Tab
  Widget _buildPlaylistsTab() {
    final playlists = controller.playlists;
    if (playlists.isEmpty) {
      return _buildEmptyTab(
        Icons.queue_music_outlined,
        '还没有歌单',
        '创建你的第一个歌单吧',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: playlists.map((w) => _buildWorkItem(w)).toList(),
      ),
    );
  }

  Widget _buildEmptyTab(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return FadeInWidget(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            Icon(icon,
                size: 44,
                color: AppTheme.textDarkGray.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSilver,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textLightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(dynamic count) {
    if (count is int) {
      if (count >= 10000) {
        return '${(count / 10000).toStringAsFixed(1)}万';
      }
      return count.toString();
    }
    return '0';
  }

  // ===== 开通VIP卡片 =====
  Widget _buildVIPCard(Map<String, dynamic> user) {
    final level = user['vip_level'] ?? 0;
    final isVIP = level >= 1;
    final isSVIP = level == 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.membership),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isSVIP
                  ? [
                      const Color(0xFFFFD700).withValues(alpha: 0.12),
                      const Color(0xFFB8860B).withValues(alpha: 0.06),
                    ]
                  : [
                      AppTheme.brandIndigo.withValues(alpha: 0.1),
                      AppTheme.brandPurple.withValues(alpha: 0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(
              color: (isSVIP ? const Color(0xFFFFD700) : AppTheme.brandIndigo).withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSVIP ? Icons.diamond_rounded : Icons.star_rounded,
                size: 22,
                color: isSVIP ? const Color(0xFFFFD700) : AppTheme.brandIndigo,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVIP ? '会员中心' : '开通VIP',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSVIP ? const Color(0xFFFFD700) : AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVIP ? '查看会员权益与音币充值' : '解锁AI无限创作 · 无损音质',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSilver,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.textDarkGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 功能入口（音乐日记、每日任务、积分商城、邀请好友、听歌统计） =====
  Widget _buildFeatureEntries() {
    final entries = [
      _FeatureEntry(
        icon: Icons.book_rounded,
        label: '音乐日记',
        subtitle: '记录心情',
        color: AppTheme.brandBlue,
        onTap: () => Get.to(() => const MusicDiaryPage()),
      ),
      _FeatureEntry(
        icon: Icons.task_alt_rounded,
        label: '每日任务',
        subtitle: '做任务赚音币',
        color: AppTheme.brandCyan,
        onTap: () => Get.toNamed(AppRoutes.dailyTasks),
      ),
      _FeatureEntry(
        icon: Icons.store_rounded,
        label: '积分商城',
        subtitle: '音币兑好礼',
        color: AppTheme.brandPurple,
        onTap: () => Get.toNamed(AppRoutes.pointsShop),
      ),
      _FeatureEntry(
        icon: Icons.people_alt_rounded,
        label: '邀请好友',
        subtitle: '邀1人得100音币',
        color: AppTheme.brandPink,
        onTap: () => Get.toNamed(AppRoutes.invite),
      ),
      _FeatureEntry(
        icon: Icons.bar_chart_rounded,
        label: '听歌统计',
        subtitle: '查看听歌数据',
        color: AppTheme.brandIndigo,
        onTap: () => _navigateToListeningStats(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 第一行：音乐日记、每日任务
          Row(
            children: [
              Expanded(child: _buildFeatureEntryItem(entries[0])),
              const SizedBox(width: 10),
              Expanded(child: _buildFeatureEntryItem(entries[1])),
            ],
          ),
          const SizedBox(height: 10),
          // 第二行：积分商城、邀请好友
          Row(
            children: [
              Expanded(child: _buildFeatureEntryItem(entries[2])),
              const SizedBox(width: 10),
              Expanded(child: _buildFeatureEntryItem(entries[3])),
            ],
          ),
          const SizedBox(height: 10),
          // 第三行：听歌统计
          _buildFeatureEntryItem(entries[4]),
        ],
      ),
    );
  }

  // 导航到听歌统计页面
  void _navigateToListeningStats() {
    // 创建模拟的听歌统计数据
    final stats = ListeningStats(
      todayMinutes: 45,
      weekMinutes: 180,
      totalSongs: 156,
      topGenres: {
        '流行': 45,
        '摇滚': 28,
        '电子': 15,
      },
      timeDistribution: {
        'morning': 12,
        'afternoon': 25,
        'evening': 35,
        'night': 8,
      },
    );
    
    Get.to(() => ListeningStatsPage(stats: stats));
  }

  /// 单个功能入口项
  Widget _buildFeatureEntryItem(_FeatureEntry entry) {
    return GestureDetector(
      onTap: entry.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: entry.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: entry.color.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(entry.icon, size: 24, color: entry.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSilver,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 签到按钮 =====
  Widget _buildCheckInButton() {
    return FutureBuilder<bool>(
      future: _isTodayCheckedIn(),
      builder: (context, snapshot) {
        final isCheckedIn = snapshot.data ?? false;
        return GestureDetector(
          onTap: () => _showCheckInPanel(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCheckedIn
                  ? AppTheme.brandIndigo.withValues(alpha: 0.15)
                  : AppTheme.surface3.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              border: Border.all(
                color: isCheckedIn
                    ? AppTheme.brandIndigo.withValues(alpha: 0.4)
                    : AppTheme.brandIndigo.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCheckedIn
                      ? Icons.check_circle_rounded
                      : Icons.calendar_today_rounded,
                  color: isCheckedIn
                      ? AppTheme.brandIndigo
                      : AppTheme.textSilver,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  isCheckedIn ? '已签到' : '签到',
                  style: TextStyle(
                    color: isCheckedIn
                        ? AppTheme.brandIndigo
                        : AppTheme.textSilver,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== 检查今日是否已签到 =====
  Future<bool> _isTodayCheckedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final checkedDates = prefs.getStringList('checked_in_dates') ?? [];
    return checkedDates.contains(today);
  }

  // ===== 执行签到 =====
  Future<void> _performCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final checkedDates = prefs.getStringList('checked_in_dates') ?? [];

    if (!checkedDates.contains(today)) {
      checkedDates.add(today);
      await prefs.setStringList('checked_in_dates', checkedDates);
    }
  }

  // ===== 显示签到面板 =====
  void _showCheckInPanel() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CheckInPanel(
        onCheckIn: () async {
          await _performCheckIn();
          // ignore: use_build_context_synchronously
          Navigator.pop(ctx);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content: const Text('签到成功！积分 +5'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== 成就徽章区域 =====
  Widget _buildAchievementSection(Map<String, dynamic> user) {
    final worksCount = user['works_count'] ?? 0;
    final likesCount = user['likes_count'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '成就',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              Text(
                '查看全部',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSilver,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface3.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
              border: Border.all(
                color: AppTheme.borderSubtle.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                // 第一行成就（4个）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBadge(
                      icon: Icons.auto_awesome_rounded,
                      label: '初出茅庐',
                      subtitle: '首次创作',
                      isUnlocked: worksCount >= 1,
                      color: AppTheme.brandPurple,
                    ),
                    _buildBadge(
                      icon: Icons.music_note_rounded,
                      label: '小有名气',
                      subtitle: '作品5首',
                      isUnlocked: worksCount >= 5,
                      color: AppTheme.brandIndigo,
                    ),
                    _buildBadge(
                      icon: Icons.headphones_rounded,
                      label: '音乐达人',
                      subtitle: '作品10首',
                      isUnlocked: worksCount >= 10,
                      color: AppTheme.brandCyan,
                    ),
                    _buildBadge(
                      icon: Icons.favorite_rounded,
                      label: '社交之星',
                      subtitle: '获得10赞',
                      isUnlocked: likesCount >= 10,
                      color: AppTheme.brandPink,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 第二行成就（4个）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBadge(
                      icon: Icons.calendar_today_rounded,
                      label: '签到达人',
                      subtitle: '连续7天',
                      isUnlocked: controller.consecutiveCheckInDays.value >= 7,
                      color: AppTheme.brandBlue,
                    ),
                    _buildBadge(
                      icon: Icons.radio_rounded,
                      label: 'FM爱好者',
                      subtitle: '使用10次',
                      isUnlocked: controller.fmUsageCount.value >= 10,
                      color: AppTheme.brandCyan,
                    ),
                    _buildBadge(
                      icon: Icons.share_rounded,
                      label: '分享达人',
                      subtitle: '分享5首',
                      isUnlocked: controller.shareCount.value >= 5,
                      color: AppTheme.brandPink,
                    ),
                    _buildBadge(
                      icon: Icons.bookmark_rounded,
                      label: '收藏家',
                      subtitle: '收藏50首',
                      isUnlocked: controller.collectedSongsCount.value >= 50,
                      color: AppTheme.brandPurple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== 单个徽章 =====
  Widget _buildBadge({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isUnlocked,
    required Color color,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 徽章圆形容器
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? color.withValues(alpha: 0.15)
                    : AppTheme.surface3,
                border: Border.all(
                  color: isUnlocked
                      ? color.withValues(alpha: 0.4)
                      : AppTheme.borderSubtle,
                  width: 1,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isUnlocked ? color : AppTheme.textDarkGray,
              ),
            ),
            // 未解锁时显示锁定图标
            if (!isUnlocked)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.surface3,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 10,
                    color: AppTheme.textDarkGray,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isUnlocked ? AppTheme.textWhite : AppTheme.textDarkGray,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: isUnlocked ? AppTheme.textSilver : AppTheme.textDarkGray,
          ),
        ),
      ],
    );
  }
}

/// 功能入口数据模型
class _FeatureEntry {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureEntry({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

// ===== 签到面板组件 =====
class _CheckInPanel extends StatelessWidget {
  final VoidCallback onCheckIn;

  const _CheckInPanel({required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppTheme.surface3,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusExtraLarge),
        ),
      ),
      child: Column(
        children: [
          // 顶部拖拽条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textDarkGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // 标题
          const Text(
            '每日签到',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 20),
          // 签到信息
          FutureBuilder<List<dynamic>>(
            future: Future.wait([
              _getCheckedDates(),
              _getConsecutiveDays(),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.brandIndigo,
                  ),
                );
              }
              final checkedDates = snapshot.data![0] as List<String>;
              final consecutiveDays = snapshot.data![1] as int;
              final points = consecutiveDays * 5;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // 连续签到信息
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoCard(
                            icon: Icons.local_fire_department_rounded,
                            value: '$consecutiveDays',
                            label: '连续签到',
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 20),
                          _buildInfoCard(
                            icon: Icons.stars_rounded,
                            value: '+$points',
                            label: '获得积分',
                            color: AppTheme.brandIndigo,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // 日历网格
                      Expanded(
                        child: _buildCalendar(checkedDates),
                      ),
                      const SizedBox(height: 20),
                      // 签到按钮
                      FutureBuilder<bool>(
                        future: _isTodayCheckedIn(),
                        builder: (context, snapshot) {
                          final isCheckedIn = snapshot.data ?? false;
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isCheckedIn ? null : onCheckIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCheckedIn
                                    ? AppTheme.surface3
                                    : AppTheme.brandIndigo,
                                foregroundColor: isCheckedIn
                                    ? AppTheme.textDarkGray
                                    : AppTheme.textWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFullPill,
                                  ),
                                  side: isCheckedIn
                                      ? const BorderSide(
                                          color: AppTheme.borderSubtle,
                                          width: 1,
                                        )
                                      : BorderSide.none,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isCheckedIn ? '今日已签到' : '立即签到',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 信息卡片
  Widget _buildInfoCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSilver,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 日历网格
  Widget _buildCalendar(List<String> checkedDates) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        // 月份标题
        Text(
          '${now.year}年${now.month}月',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 16),
        // 星期标题
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['一', '二', '三', '四', '五', '六', '日']
              .map((day) => Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSilver,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // 日期网格
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday - 1 + lastDayOfMonth.day,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }
              final day = index - firstWeekday + 2;
              final dateStr =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final isChecked = checkedDates.contains(dateStr);
              final isToday = day == now.day;

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked
                      ? AppTheme.brandIndigo.withValues(alpha: 0.3)
                      : Colors.transparent,
                  border: isToday
                      ? Border.all(
                          color: AppTheme.brandIndigo,
                          width: 1,
                        )
                      : null,
                ),
                child: Center(
                  child: isChecked
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: isToday
                              ? AppTheme.brandIndigo
                              : AppTheme.textSilver,
                        )
                      : Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            color: isToday
                                ? AppTheme.brandIndigo
                                : AppTheme.textSilver,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 获取签到记录
  Future<List<String>> _getCheckedDates() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('checked_in_dates') ?? [];
  }

  // 获取连续签到天数
  Future<int> _getConsecutiveDays() async {
    final checkedDates = await _getCheckedDates();
    if (checkedDates.isEmpty) return 0;

    int consecutive = 0;
    final today = DateTime.now();
    final todayStr = today.toString().substring(0, 10);

    DateTime checkDate = checkedDates.contains(todayStr)
        ? today
        : today.subtract(const Duration(days: 1));

    while (true) {
      final dateStr = checkDate.toString().substring(0, 10);
      if (checkedDates.contains(dateStr)) {
        consecutive++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return consecutive;
  }

  // 检查今日是否已签到
  Future<bool> _isTodayCheckedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final checkedDates = prefs.getStringList('checked_in_dates') ?? [];
    return checkedDates.contains(today);
  }
}
