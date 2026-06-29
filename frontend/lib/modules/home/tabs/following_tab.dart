import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/services/post_service.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

class FollowingTab extends StatefulWidget {
  const FollowingTab({super.key});

  @override
  State<FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends State<FollowingTab> with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  final RxList posts = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString errorMsg = ''.obs;
  // 记录正在关注中的用户ID，防止重复点击
  final RxSet<int> _followingUsers = <int>{}.obs;

  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  static const int _pageSize = 20;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    loadData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  Future<void> loadData() async {
    isLoading.value = true;
    _page = 1;
    errorMsg.value = '';
    try {
      final response = await _api.get('post/list', queryParameters: {'type': 'following', 'page': _page, 'page_size': _pageSize});
      final list = _extractList(response);
      posts.value = list;
      hasMore.value = list.length >= _pageSize;
    } catch (e) {
      debugPrint('加载关注动态失败: $e');
      errorMsg.value = '加载失败';
      posts.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    _page = 1;
    try {
      final response = await _api.get('post/list', queryParameters: {'type': 'following', 'page': _page, 'page_size': _pageSize});
      final list = _extractList(response);
      posts.value = list;
      hasMore.value = list.length >= _pageSize;
      errorMsg.value = '';
    } catch (e) {
      debugPrint('刷新关注动态失败: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    _page++;
    try {
      final response = await _api.get('post/list', queryParameters: {'type': 'following', 'page': _page, 'page_size': _pageSize});
      final list = _extractList(response);
      if (list.isEmpty) {
        hasMore.value = false;
      } else {
        posts.addAll(list);
        hasMore.value = list.length >= _pageSize;
      }
    } catch (e) {
      _page--;
      debugPrint('加载更多动态失败: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic response) {
    if (response is Map) {
      final data = response['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['list'] is List) return (data['list'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// 点赞动态，成功后更新本地状态
  Future<void> _likePost(Map post) async {
    final postId = post['id'] as int?;
    if (postId == null) return;
    try {
      final postService = Get.find<PostService>();
      final success = await postService.likePost(postId);
      if (success) {
        // 切换本地点赞状态并更新计数
        final isLiked = post['is_liked'] == true;
        post['is_liked'] = !isLiked;
        post['like_count'] = (post['like_count'] ?? 0) + (isLiked ? -1 : 1);
        posts.refresh();
      }
    } catch (e) {
      debugPrint('点赞失败: $e');
      ToastUtil.showError('点赞失败');
    }
  }

  /// 弹出评论输入框
  void _showCommentInput(Map post) {
    final postId = post['id'] as int?;
    if (postId == null) return;
    final commentController = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示条
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                '评论',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        autofocus: true,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: InputDecoration(
                          hintText: '写评论...',
                          hintStyle: const TextStyle(color: AppTheme.textLightGray),
                          filled: true,
                          fillColor: AppTheme.midDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final content = commentController.text.trim();
                        if (content.isEmpty) return;
                        try {
                          final postService = Get.find<PostService>();
                          final success = await postService.addPostComment(
                            postId: postId,
                            content: content,
                          );
                          if (success) {
                            Get.back();
                            ToastUtil.showSuccess('评论已发布');
                            // 更新评论计数
                            post['comment_count'] = (post['comment_count'] ?? 0) + 1;
                            posts.refresh();
                          }
                        } catch (e) {
                          debugPrint('评论失败: $e');
                          ToastUtil.showError('评论失败');
                        }
                      },
                      child: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 关注用户，成功后更新动态列表中该用户的所有动态状态
  Future<void> _followUser(int userId) async {
    if (_followingUsers.contains(userId)) return;
    _followingUsers.add(userId);
    try {
      final response = await _api.post('user/follow/$userId');
      if (response is Map && (response['code'] == 0 || response['code'] == 200)) {
        // 更新列表中该用户的所有动态的关注状态
        for (int i = 0; i < posts.length; i++) {
          final creator = posts[i]['creator'] as Map<String, dynamic>?;
          final creatorId = (creator?['user_id'] ?? creator?['id'] ?? posts[i]['user_id']) as int? ?? 0;
          if (creatorId == userId) {
            posts[i]['is_followed'] = true;
          }
        }
        posts.refresh();
      }
    } catch (e) {
      debugPrint('关注失败: $e');
      ToastUtil.showError('关注失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      if (isLoading.value) {
        return _buildLoadingView();
      }

      if (errorMsg.value.isNotEmpty && posts.isEmpty) {
        return _buildErrorView();
      }

      if (posts.isEmpty) {
        return _buildEmptyView();
      }

      return RefreshIndicator(
        onRefresh: refreshData,
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.darkSurface,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: posts.length + (isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= posts.length) {
              return _buildLoadingIndicator();
            }
            return FadeInWidget(
              delayMs: (index % 20) * 50,
              child: _buildPostItem(posts[index]),
            );
          },
        ),
      );
    });
  }

  Widget _buildPostItem(Map post) {
    final creator = post['creator'] as Map<String, dynamic>? ?? {};
    final creatorId = (creator['user_id'] ?? creator['id'] ?? post['user_id']) as int? ?? 0;
    final hasImage = post['image'] != null && post['image'].toString().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(color: AppTheme.borderGray.withOpacity(0.15), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息头部
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.publicProfile, arguments: creatorId),
                    child: ClipOval(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                          ),
                        ),
                        child: creator['avatar'] != null && creator['avatar'].toString().isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: creator['avatar'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, color: AppTheme.textWhite, size: 20),
                              )
                            : const Icon(Icons.person_rounded, color: AppTheme.textWhite, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name & time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          creator['nickname'] ?? creator['username'] ?? '用户',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(post['created_at']),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMediumGray),
                        ),
                      ],
                    ),
                  ),
                  // 关注按钮
                  if (post['is_followed'] != true)
                    Obx(() {
                      final isFollowing = _followingUsers.contains(creatorId);
                      return TextButton(
                        onPressed: isFollowing ? null : () => _followUser(creatorId),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: isFollowing
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryColor),
                              )
                            : const Text(
                                '关注',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                              ),
                      );
                    }),
                ],
              ),
            ),
            // 内容
            if (post['content'] != null && post['content'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Text(
                  post['content'],
                  style: const TextStyle(fontSize: 14, color: AppTheme.textWhite, height: 1.5),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // 图片
            if (hasImage)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: post['image'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: AppTheme.midDark,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 200,
                      color: AppTheme.midDark,
                      child: const Icon(Icons.broken_image_outlined, color: AppTheme.textDarkGray),
                    ),
                  ),
                ),
              ),
            // 关联音乐
            if (post['music_id'] != null)
              _buildMusicAttachment(post),
            // 操作栏
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _likePost(post),
                    child: _buildActionButton(
                      post['is_liked'] == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      '${post['like_count'] ?? 0}',
                      color: post['is_liked'] == true ? AppTheme.brandPink : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => _showCommentInput(post),
                    child: _buildActionButton(Icons.chat_bubble_outline_rounded, '${post['comment_count'] ?? 0}'),
                  ),
                  const Spacer(),
                  if (post['id'] != null)
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.post, arguments: post['id']),
                      child: const Text(
                        '查看详情',
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
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

  Widget _buildMusicAttachment(Map post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.midDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElasticButton(
          onTap: () => Get.toNamed(AppRoutes.musicDetail, arguments: post['music_id']),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.music_note_rounded, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post['music_title'] ?? post['song_title'] ?? '歌曲',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textWhite),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.play_circle_outline_rounded, size: 20, color: AppTheme.textSilver),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String count, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? AppTheme.textLightGray),
        const SizedBox(width: 4),
        Text(count, style: TextStyle(fontSize: 12, color: color ?? AppTheme.textLightGray)),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerLoading(width: 40, height: 40, borderRadius: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLoading(width: 100, height: 14),
                          SizedBox(height: 4),
                          ShimmerLoading(width: 60, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const ShimmerLoading(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                const ShimmerLoading(width: 200, height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return RefreshIndicator(
      onRefresh: refreshData,
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.darkSurface,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rss_feed_rounded, size: 64, color: AppTheme.textDarkGray.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无关注动态',
                    style: TextStyle(fontSize: 16, color: AppTheme.textSilver),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '关注感兴趣的创作者，动态会显示在这里',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMediumGray),
                  ),
                  const SizedBox(height: 24),
                  ElasticButton(
                    onTap: refreshData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                      ),
                      child: const Text(
                        '刷新试试',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textWhite),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.textDarkGray),
          const SizedBox(height: 16),
          const Text(
            '网络开小差了',
            style: TextStyle(fontSize: 16, color: AppTheme.textSilver),
          ),
          const SizedBox(height: 24),
          ElasticButton(
            onTap: loadData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              ),
              child: const Text(
                '重新加载',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textWhite),
              ),
            ),
          ),
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
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    return time.toString();
  }
}
