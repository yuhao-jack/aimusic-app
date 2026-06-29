import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/modules/profile/public_profile_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

/// 公开个人主页（他人视角）
/// 展示用户头像、昵称、简介、统计数据，支持关注/取消关注
/// Tab切换：作品列表 / 动态列表，作品以瀑布流形式展示
class PublicProfilePage extends GetView<PublicProfileController> {
  const PublicProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final int userId = Get.arguments as int;
    controller.loadData(userId);

    return Scaffold(
      backgroundColor: AppTheme.surface1,
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingView();
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            _buildProfileHeader(),
            _buildStatsRow(),
            _buildTabBar(),
            _buildTabContent(),
          ],
        );
      }),
    );
  }

  // ===== 加载占位 =====
  Widget _buildLoadingView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: Colors.transparent,
          leading: _buildBackButton(),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryColor, AppTheme.surface1],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: PageShimmer(itemCount: 4),
          ),
        ),
      ],
    );
  }

  // ===== 顶部渐变 AppBar =====
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.primaryColor, AppTheme.surface1],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textWhite),
      onPressed: () => Get.back(),
    );
  }

  // ===== 个人信息头部 =====
  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: FadeInWidget(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              // 头像 + 昵称 + 简介
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头像
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  // 昵称 + 简介
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() => Text(
                              controller.userInfo.value?['nickname'] ?? '用户',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textWhite,
                              ),
                            )),
                        const SizedBox(height: 6),
                        Obx(() => Text(
                              controller.userInfo.value?['bio'] ?? '这个人很懒，什么都没写',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSilver,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 关注按钮
              Obx(() => _buildFollowButton()),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 头像 =====
  Widget _buildAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Obx(() {
          final avatar = controller.userInfo.value?['avatar']?.toString() ?? '';
          return avatar.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatar,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: AppTheme.textWhite,
                  ),
                )
              : const Icon(Icons.person_rounded, size: 40, color: AppTheme.textWhite);
        }),
      ),
    );
  }

  // ===== 关注/取消关注按钮 =====
  Widget _buildFollowButton() {
    return ElasticButton(
      onTap: controller.followLoading.value ? null : controller.toggleFollow,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: controller.isFollowed.value
              ? AppTheme.surface3
              : AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          border: controller.isFollowed.value
              ? Border.all(color: AppTheme.borderGray.withOpacity(0.5))
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (controller.followLoading.value)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textWhite,
                  ),
                )
              else ...[
                Icon(
                  controller.isFollowed.value
                      ? Icons.check_rounded
                      : Icons.add_rounded,
                  size: 18,
                  color: controller.isFollowed.value
                      ? AppTheme.textSilver
                      : AppTheme.textWhite,
                ),
                const SizedBox(width: 6),
                Text(
                  controller.isFollowed.value ? '已关注' : '关注',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: controller.isFollowed.value
                        ? AppTheme.textSilver
                        : AppTheme.textWhite,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===== 统计数据行 =====
  Widget _buildStatsRow() {
    return SliverToBoxAdapter(
      child: FadeInWidget(
        delay: const Duration(milliseconds: 100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Obx(
            () => Row(
              children: [
                _buildStatItem(
                  controller.followerCount.value.toString(),
                  '粉丝',
                  onTap: () => Get.toNamed(AppRoutes.follow,
                      arguments: {'userId': controller.userId.value, 'type': 0}),
                ),
                _buildStatDivider(),
                _buildStatItem(
                  controller.followingCount.value.toString(),
                  '关注',
                  onTap: () => Get.toNamed(AppRoutes.follow,
                      arguments: {'userId': controller.userId.value, 'type': 1}),
                ),
                _buildStatDivider(),
                _buildStatItem(
                  controller.workCount.value.toString(),
                  '作品',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSilver),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppTheme.borderGray.withOpacity(0.3),
    );
  }

  // ===== Tab 栏 =====
  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: FadeInWidget(
        delay: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          ),
          child: Row(
            children: [
              _buildTabItem('作品', 0),
              _buildTabItem('动态', 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    return Expanded(
      child: Obx(
        () => GestureDetector(
          onTap: () => controller.switchTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: controller.currentTab.value == index
                  ? AppTheme.primaryColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: controller.currentTab.value == index
                    ? AppTheme.primaryColor
                    : AppTheme.textSilver,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== Tab 内容区 =====
  Widget _buildTabContent() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final padding = const EdgeInsets.fromLTRB(20, 16, 20, 100);

        switch (controller.currentTab.value) {
          case 0:
            return Padding(
              padding: padding,
              child: _buildWorksGrid(),
            );
          case 1:
            return Padding(
              padding: padding,
              child: _buildPostsList(),
            );
          default:
            return const SizedBox.shrink();
        }
      }),
    );
  }

  // ===== 作品瀑布流 =====
  Widget _buildWorksGrid() {
    if (controller.works.isEmpty) {
      return _buildEmptyState('暂无作品', Icons.music_note_outlined);
    }

    return Column(
      children: [
        // 瀑布流两列
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左列
            Expanded(
              child: Column(
                children: List.generate(
                  (controller.works.length / 2).ceil(),
                  (index) => FadeInWidget(
                    delayMs: index * 80,
                    child: _buildWorkCard(controller.works[index * 2]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 右列
            Expanded(
              child: Column(
                children: List.generate(
                  controller.works.length ~/ 2,
                  (index) => FadeInWidget(
                    delayMs: (index * 2 + 1) * 80,
                    child: _buildWorkCard(controller.works[index * 2 + 1]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===== 作品卡片（瀑布流单张） =====
  Widget _buildWorkCard(Map work) {
    final cover = work['cover_url'] ?? work['cover'] ?? '';
    final title = work['title'] ?? '未知歌曲';
    final playCount = work['play_count'] ?? 0;
    // 随机高度模拟瀑布流效果（基于标题长度）
    final double cardHeight = 160 + (title.hashCode.abs() % 80).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElasticButton(
        onTap: () => Get.toNamed(AppRoutes.musicDetail, arguments: work['id']),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(
              color: AppTheme.borderGray.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusComfortable),
                ),
                child: Container(
                  width: double.infinity,
                  height: cardHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                  ),
                  child: cover.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.music_note_rounded,
                                size: 40, color: Colors.white30),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.music_note_rounded,
                              size: 40, color: Colors.white30),
                        ),
                ),
              ),
              // 标题 + 播放量
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.play_arrow_rounded,
                            size: 14, color: AppTheme.textLightGray),
                        const SizedBox(width: 2),
                        Text(
                          _formatCount(playCount),
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
            ],
          ),
        ),
      ),
    );
  }

  // ===== 动态列表 =====
  Widget _buildPostsList() {
    if (controller.posts.isEmpty) {
      return _buildEmptyState('暂无动态', Icons.article_outlined);
    }

    return Column(
      children: List.generate(controller.posts.length, (index) {
        return FadeInWidget(
          delayMs: index * 60,
          child: _buildPostItem(controller.posts[index]),
        );
      }),
    );
  }

  Widget _buildPostItem(Map post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElasticButton(
        onTap: () => Get.toNamed(AppRoutes.post, arguments: post['id']),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(
              color: AppTheme.borderGray.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'] ??
                      post['content']?.toString().substring(
                            0,
                            (post['content']?.toString().length ?? 0)
                                .clamp(0, 40),
                          ) ??
                      '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  post['content'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSilver,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.favorite_border_rounded,
                        size: 14, color: AppTheme.textLightGray),
                    const SizedBox(width: 4),
                    Text(
                      '${post['like_count'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 14, color: AppTheme.textLightGray),
                    const SizedBox(width: 4),
                    Text(
                      '${post['comment_count'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== 空状态 =====
  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(icon, size: 64, color: AppTheme.textDarkGray.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: AppTheme.textSilver),
          ),
        ],
      ),
    );
  }

  // ===== 数字格式化 =====
  String _formatCount(dynamic count) {
    final int c = count is int ? count : int.tryParse(count.toString()) ?? 0;
    if (c >= 10000) {
      return '${(c / 10000).toStringAsFixed(1)}万';
    }
    return c.toString();
  }
}
