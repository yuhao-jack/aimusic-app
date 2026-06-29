import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/modules/creator/creator_controller.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

class CreatorDetailPage extends StatelessWidget {
  const CreatorDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CreatorController controller = Get.put(CreatorController());
    final int userId = Get.arguments as int;

    controller.loadData(userId);

    return Scaffold(
      backgroundColor: AppTheme.surface1,
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingView();
        }

        final creator = controller.creator.value;
        if (creator == null) {
          return _buildErrorView();
        }

        return CustomScrollView(
          slivers: [
            _buildSliverAppBar(creator, controller),
            _buildProfileHeader(creator, controller),
            _buildTabBar(controller),
            _buildTabContent(controller),
          ],
        );
      }),
    );
  }

  Widget _buildLoadingView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.textDarkGray),
          const SizedBox(height: 16),
          const Text('加载失败', style: TextStyle(fontSize: 16, color: AppTheme.textSilver)),
          const SizedBox(height: 24),
          ElasticButton(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              ),
              child: const Text('返回', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textWhite),
      onPressed: () => Get.back(),
    );
  }

  Widget _buildSliverAppBar(Map creator, CreatorController controller) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor,
                AppTheme.surface1,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map creator, CreatorController controller) {
    return SliverToBoxAdapter(
      child: FadeInWidget(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              // 头像和基本信息
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
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
                      child: creator['avatar'] != null && creator['avatar'].toString().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: creator['avatar'],
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.person_rounded, size: 40, color: AppTheme.textWhite,
                              ),
                            )
                          : const Icon(Icons.person_rounded, size: 40, color: AppTheme.textWhite),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 名字和简介
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          creator['nickname'] ?? '创作者',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          creator['bio'] ?? creator['description'] ?? '这个人很懒，什么都没写',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSilver,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 关注按钮
              Obx(() => _buildFollowButton(controller)),
              const SizedBox(height: 20),
              // 统计数据
              _buildStatsRow(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(CreatorController controller) {
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
                  controller.isFollowed.value ? Icons.check_rounded : Icons.add_rounded,
                  size: 18,
                  color: controller.isFollowed.value ? AppTheme.textSilver : AppTheme.textWhite,
                ),
                const SizedBox(width: 6),
                Text(
                  controller.isFollowed.value ? '已关注' : '关注',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: controller.isFollowed.value ? AppTheme.textSilver : AppTheme.textWhite,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(CreatorController controller) {
    return Obx(
      () => Row(
        children: [
          _buildStatItem(controller.followerCount.value.toString(), '粉丝', onTap: () {
            Get.toNamed(AppRoutes.follow, arguments: {'userId': controller.userId.value, 'type': 0});
          }),
          _buildStatDivider(),
          _buildStatItem(controller.followingCount.value.toString(), '关注', onTap: () {
            Get.toNamed(AppRoutes.follow, arguments: {'userId': controller.userId.value, 'type': 1});
          }),
          _buildStatDivider(),
          _buildStatItem(controller.workCount.value.toString(), '作品'),
        ],
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

  Widget _buildTabBar(CreatorController controller) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        ),
        child: Row(
          children: [
            _buildTabItem('作品', 0, controller),
            _buildTabItem('动态', 1, controller),
            _buildTabItem('歌单', 2, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index, CreatorController controller) {
    return Expanded(
      child: Obx(
        () => GestureDetector(
          onTap: () => controller.switchTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: controller.currentTabIndex.value == index
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
                color: controller.currentTabIndex.value == index
                    ? AppTheme.primaryColor
                    : AppTheme.textSilver,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(CreatorController controller) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final index = controller.currentTabIndex.value;
        final padding = const EdgeInsets.fromLTRB(20, 16, 20, 100);

        switch (index) {
          case 0:
            return Padding(
              padding: padding,
              child: _buildSongsList(controller),
            );
          case 1:
            return Padding(
              padding: padding,
              child: _buildPostsList(controller),
            );
          case 2:
            return Padding(
              padding: padding,
              child: _buildPlaylistsList(controller),
            );
          default:
            return const SizedBox.shrink();
        }
      }),
    );
  }

  // ========== 作品 Tab ==========
  Widget _buildSongsList(CreatorController controller) {
    if (controller.songs.isEmpty) {
      return _buildEmptyState('暂无作品', Icons.music_note_outlined);
    }

    return Column(
      children: List.generate(controller.songs.length, (index) {
        return FadeInWidget(
          delayMs: index * 60,
          child: _buildSongItem(controller.songs[index]),
        );
      }),
    );
  }

  Widget _buildSongItem(Map song) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElasticButton(
        onTap: () => Get.toNamed(AppRoutes.musicDetail, arguments: song['id']),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(color: AppTheme.borderGray.withOpacity(0.2), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                    ),
                    child: song['cover_url'] != null && song['cover_url'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: song['cover_url'],
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: AppTheme.textWhite),
                          )
                        : const Icon(Icons.music_note, color: AppTheme.textWhite, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title'] ?? '未知歌曲',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (song['style'] != null && song['style'].toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface3,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                song['style'],
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSilver),
                              ),
                            ),
                          Text(
                            song['play_count']?.toString() ?? '0',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textLightGray),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.play_arrow_rounded, size: 14, color: AppTheme.textLightGray),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_outline_rounded, color: AppTheme.primaryColor, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== 动态 Tab ==========
  Widget _buildPostsList(CreatorController controller) {
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
            border: Border.all(color: AppTheme.borderGray.withOpacity(0.2), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      post['title'] ?? post['content']?.toString().substring(0, (post['content']?.toString().length ?? 0).clamp(0, 40)) ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post['content'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSilver),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.favorite_border_rounded, size: 14, color: AppTheme.textLightGray),
                    const SizedBox(width: 4),
                    Text(
                      '${post['like_count'] ?? 0}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textLightGray),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppTheme.textLightGray),
                    const SizedBox(width: 4),
                    Text(
                      '${post['comment_count'] ?? 0}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textLightGray),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(post['created_at']),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMediumGray),
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

  // ========== 歌单 Tab ==========
  Widget _buildPlaylistsList(CreatorController controller) {
    if (controller.playlists.isEmpty) {
      return _buildEmptyState('暂无歌单', Icons.playlist_play_rounded);
    }

    return Column(
      children: List.generate(controller.playlists.length, (index) {
        return FadeInWidget(
          delayMs: index * 60,
          child: _buildPlaylistItem(controller.playlists[index]),
        );
      }),
    );
  }

  Widget _buildPlaylistItem(Map playlist) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElasticButton(
        onTap: () => Get.toNamed(AppRoutes.playlist, arguments: playlist['id']),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(color: AppTheme.borderGray.withOpacity(0.2), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                    ),
                    child: playlist['cover'] != null && playlist['cover'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: playlist['cover'],
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.playlist_play_rounded, color: AppTheme.textWhite),
                          )
                        : const Icon(Icons.playlist_play_rounded, color: AppTheme.textWhite, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist['name'] ?? '未命名歌单',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist['song_count'] ?? 0} 首',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSilver),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textDarkGray),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== 通用组件 ==========
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

  String _formatTime(dynamic time) {
    if (time == null) return '';
    return time.toString();
  }
}
