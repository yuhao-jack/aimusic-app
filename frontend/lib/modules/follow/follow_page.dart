import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/modules/follow/follow_controller.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

class FollowPage extends StatefulWidget {
  const FollowPage({super.key});

  @override
  State<FollowPage> createState() => _FollowPageState();
}

class _FollowPageState extends State<FollowPage> with AutomaticKeepAliveClientMixin {
  final FollowController controller = Get.find<FollowController>();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    final userId = (args['user_id'] as int?) ?? 0;
    final type = (args['type'] as int?) ?? 0; // 0=粉丝, 1=关注

    controller.init(userId, type);

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingView();
        }

        if (controller.users.isEmpty) {
          return _buildEmptyView();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.surface3,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: controller.users.length + (controller.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.users.length) {
                return _buildLoadingIndicator();
              }
              return FadeInWidget(
                delayMs: (index % 20) * 40,
                child: _buildUserItem(controller.users[index]),
              );
            },
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface1,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textWhite),
        onPressed: () => Get.back(),
      ),
      title: Obx(() => Text(
        controller.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textWhite,
        ),
      )),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          ),
          child: Row(
            children: [
              _buildTypeTab('粉丝', 0),
              _buildTypeTab('关注', 1),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildTypeTab(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchType(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: controller.type.value == index
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
              color: controller.type.value == index
                  ? AppTheme.primaryColor
                  : AppTheme.textSilver,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    final uid = (user['user_id'] ?? user['id']) as int? ?? 0;
    final isFollowed = controller.isUserFollowed(uid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElasticButton(
        onTap: () => Get.toNamed(AppRoutes.publicProfile, arguments: uid),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(color: AppTheme.borderGray.withOpacity(0.15), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                ClipOval(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                    ),
                    child: user['avatar'] != null && user['avatar'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user['avatar'],
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, color: AppTheme.textWhite, size: 24),
                          )
                        : const Icon(Icons.person_rounded, color: AppTheme.textWhite, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nickname'] ?? user['username'] ?? '用户',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user['bio'] ?? user['description'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSilver),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 关注/已关注按钮
                ElasticButton(
                  onTap: () => controller.toggleFollowForUser(uid),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFollowed ? AppTheme.surface3 : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                      border: isFollowed
                          ? Border.all(color: AppTheme.borderGray.withOpacity(0.4))
                          : null,
                    ),
                    child: Text(
                      isFollowed ? '已关注' : '关注',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFollowed ? AppTheme.textSilver : AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          6,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const ShimmerLoading(width: 48, height: 48, borderRadius: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(width: 120, height: 16),
                      SizedBox(height: 6),
                      ShimmerLoading(width: 180, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() => Icon(
            controller.type.value == 0
                ? Icons.person_outline_rounded
                : Icons.people_outline_rounded,
            size: 64,
            color: AppTheme.textDarkGray.withOpacity(0.5),
          )),
          const SizedBox(height: 16),
          Obx(() => Text(
            controller.type.value == 0 ? '暂无粉丝' : '暂无关注',
            style: const TextStyle(fontSize: 16, color: AppTheme.textSilver),
          )),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
