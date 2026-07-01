import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/modules/music/music_detail_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/utils/share_util.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

/// 音乐详情页 - 沉浸式封面、歌词预览、相关推荐
/// 视觉升级：封面更大圆角更亮光晕、歌词卡片 surface2 分层、评论输入框更圆润
class MusicDetailPage extends GetView<MusicDetailController> {
  MusicDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dynamicBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 2.0,
            colors: [
              AppTheme.primary.withOpacity(0.06),
              AppTheme.dynamicBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return _buildDetailShimmer();
            }
            final music = controller.music;
            return SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Top bar
                  _buildTopBar(),
                  // Cover + Info
                  _buildCoverSection(music),
                  // Action buttons
                  _buildActionRow(music),
                  SizedBox(height: 24),
                  // Lyric preview
                  _buildLyricPreview(music),
                  SizedBox(height: 24),
                  // Hot comments section
                  _buildHotCommentsSection(),
                  SizedBox(height: 24),
                  // Comments section
                  _buildCommentsSection(),
                  SizedBox(height: 100),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // ===== 骨架屏 - 封面+标题+歌手+按钮区域占位 =====
  Widget _buildDetailShimmer() {
    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // 顶部栏占位
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surface3,
                    shape: BoxShape.circle,
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
          // 封面占位
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                SizedBox(height: 20),
                ShimmerLoading(
                  width: double.infinity,
                  height: 280,
                  borderRadius: AppTheme.radiusExtraLarge,
                ),
                SizedBox(height: 28),
                // 标题占位
                ShimmerLoading(width: 200, height: 26),
                SizedBox(height: 12),
                // 歌手占位
                ShimmerLoading(width: 100, height: 28),
              ],
            ),
          ),
          SizedBox(height: 24),
          // 按钮区域占位
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                Expanded(
                  child: ShimmerLoading(
                    width: double.infinity,
                    height: 52,
                    borderRadius: AppTheme.radiusFullPill,
                  ),
                ),
                SizedBox(width: 16),
                ShimmerLoading(width: 52, height: 52, borderRadius: 26),
                SizedBox(width: 12),
                ShimmerLoading(width: 52, height: 52, borderRadius: 26),
              ],
            ),
          ),
          SizedBox(height: 24),
          // 歌词预览占位
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ShimmerLoading(
              width: double.infinity,
              height: 160,
              borderRadius: AppTheme.radiusLarge,
            ),
          ),
        ],
      ),
    );
  }

  // ===== Top Bar =====
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          ElasticButton(
            onTap: () => Get.back(),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded,
                    color: AppTheme.textWhite, size: 20),
              ),
            ),
          ),
          Spacer(),
          Obx(() => ElasticButton(
                onTap: () => ShareUtil.shareSong(
                    Map<String, dynamic>.from(controller.music)),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface3,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.share_outlined,
                        color: AppTheme.textWhite, size: 20),
                  ),
                ),
              )),
          SizedBox(width: 8),
          ElasticButton(
            onTap: () => _showMoreMenu(Get.context!),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.more_vert_rounded,
                    color: AppTheme.textWhite, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Cover Section =====
  Widget _buildCoverSection(Map music) {
    final cover = music['cover'] ?? music['cover_url'] ?? '';
    return FadeInWidget(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            SizedBox(height: 20),
            // Cover image - larger radius, deeper glow
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusExtraLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 50,
                    offset: Offset(0, 20),
                  ),
                  BoxShadow(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    blurRadius: 35,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Hero(
                tag: 'song_cover_${music['id']}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      AppTheme.radiusExtraLarge),
                  child: cover.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              _buildPlaceholderCover(),
                          errorWidget: (_, __, ___) =>
                              _buildPlaceholderCover(),
                        )
                      : _buildPlaceholderCover(),
                ),
              ),
            ),
            SizedBox(height: 28),
            // Title
            Text(
              music['title'] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
                letterSpacing: 0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            // Artist + Genre
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.15),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    music['artist'] ?? music['singer'] ?? '未知歌手',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (music['genre'] != null) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface3,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      music['genre'],
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSilver,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.music_note_rounded,
            size: 80, color: Colors.white30),
      ),
    );
  }

  // ===== Action Row =====
  Widget _buildActionRow(Map music) {
    return FadeInWidget(
      delay: Duration(milliseconds: 100),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Play gradient button
            Expanded(
              child: ElasticButton(
                onTap: () => Get.toNamed(AppRoutes.player,
                    arguments: music),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryToSecondary,
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusFullPill),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppTheme.primaryColor.withOpacity(0.35),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                      BoxShadow(
                        color:
                            AppTheme.secondaryColor.withOpacity(0.15),
                        blurRadius: 30,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: AppTheme.textWhite, size: 28),
                      SizedBox(width: 8),
                      Text(
                        '播放',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            // Like - elevated surface
            Obx(() => LikeButton(
                  isLiked: controller.isLiked.value,
                  size: 24,
                  activeColor: AppTheme.brandPurple,
                  onTap: controller.toggleLike,
                )),
            SizedBox(width: 12),
            // 添加到歌单
            ElasticButton(
              onTap: () => _showAddToPlaylistSheet(Get.context!),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.playlist_add_rounded,
                    color: AppTheme.textSilver, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Lyric Preview =====
  Widget _buildLyricPreview(Map music) {
    return FadeInWidget(
      delay: Duration(milliseconds: 200),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius:
              BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.borderSubtle.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.lyrics_rounded,
                          size: 16, color: AppTheme.primaryColor),
                    ),
                    SizedBox(width: 10),
                    Text(
                      '歌词',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.player,
                      arguments: music),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('查看全部'),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Container(
              height: 0.5,
              color: AppTheme.borderSubtle.withOpacity(0.4),
            ),
            SizedBox(height: 12),
            Text(
              music['lyric'] ??
                  music['lyrics'] ??
                  '暂无歌词信息',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSilver,
                height: 1.8,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===== Hot Comments Section (热评区域) =====
  Widget _buildHotCommentsSection() {
    return Obx(() {
      if (controller.hotComments.isEmpty) return SizedBox.shrink();

      return FadeInWidget(
        delay: Duration(milliseconds: 250),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.local_fire_department_rounded,
                        size: 16, color: AppTheme.brandPink),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '热评',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // 热评卡片
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface3,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusComfortable),
                  border: Border.all(
                    color: AppTheme.borderSubtle.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    // 热评列表（最多3条）
                    ...controller.hotComments.map((comment) {
                      final username =
                          comment['username'] ?? comment['user']?['name'] ?? '用户';
                      final content = comment['content'] ?? '';
                      final likeCount = comment['like_count'] ?? 0;
                      final avatar =
                          comment['avatar'] ?? comment['user']?['avatar'] ?? '';
                      return _buildHotCommentItem(
                        username: username,
                        content: content,
                        likeCount: likeCount,
                        avatar: avatar,
                      );
                    }),
                    // 查看全部评论按钮
                    _buildViewAllCommentsButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 单条热评
  Widget _buildHotCommentItem({
    required String username,
    required String content,
    required int likeCount,
    required String avatar,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
            child: avatar.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatar,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: AppTheme.primaryColor),
                    ),
                  )
                : Icon(Icons.person_rounded,
                    size: 18, color: AppTheme.primaryColor),
          ),
          SizedBox(width: 10),
          // 内容区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textWhite,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          // 点赞数
          Column(
            children: [
              Icon(Icons.favorite_rounded,
                  size: 14, color: AppTheme.brandPink),
              SizedBox(height: 2),
              Text(
                _formatCount(likeCount),
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textLightGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 查看全部评论按钮
  Widget _buildViewAllCommentsButton() {
    return GestureDetector(
      onTap: () {
        // 滚动到评论区域（通过延迟滚动确保布局完成）
        Future.delayed(Duration(milliseconds: 100), () {
          // 跳转到播放器页面的评论 Tab，或展开全部评论
          Get.toNamed(AppRoutes.player,
              arguments: controller.music);
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.borderSubtle.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '查看全部评论',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textLightGray,
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: AppTheme.textLightGray),
          ],
        ),
      ),
    );
  }

  /// 数字格式化
  String _formatCount(dynamic count) {
    final int c =
        count is int ? count : int.tryParse(count.toString()) ?? 0;
    if (c >= 10000) {
      return '${(c / 10000).toStringAsFixed(1)}万';
    }
    return c.toString();
  }

  // ===== Comments Section =====
  Widget _buildCommentsSection() {
    return FadeInWidget(
      delay: Duration(milliseconds: 300),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded,
                          size: 16, color: AppTheme.primaryColor),
                    ),
                    SizedBox(width: 10),
                    Text(
                      '评论',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            // Comment input - more rounded, subtle border
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: BorderRadius.circular(
                    AppTheme.radiusComfortable),
                border: Border.all(
                  color: AppTheme.borderSubtle.withOpacity(0.5),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: controller.commentController,
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '说点什么...',
                          hintStyle: TextStyle(
                            color: AppTheme.textLightGray,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send_rounded,
                        color: AppTheme.primaryColor, size: 20),
                    onPressed: () => controller.addComment(
                        controller.commentController.text),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // 评论列表 - 从API加载
            Obx(() {
              if (controller.comments.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '暂无评论，快来抢沙发吧~',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLightGray,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: controller.comments.map((comment) {
                  final username = comment['username'] ?? comment['user']?['name'] ?? '用户';
                  final content = comment['content'] ?? '';
                  final createdAt = comment['created_at'] ?? '';
                  final likeCount = comment['like_count'] ?? 0;
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface3,
                      borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 头像
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                          child: Icon(Icons.person_rounded,
                              size: 18,
                              color: AppTheme.primaryColor),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    username,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _formatTime(createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textLightGray,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                content,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textWhite,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => controller.likeComment(comment),
                                    child: Icon(
                                      comment['is_liked'] == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      size: 14,
                                      color: comment['is_liked'] == true ? AppTheme.brandPink : AppTheme.textLightGray,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '$likeCount',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: comment['is_liked'] == true ? AppTheme.brandPink : AppTheme.textLightGray),
                                  ),
                                  SizedBox(width: 16),
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 14, color: AppTheme.textLightGray),
                                  SizedBox(width: 4),
                                  Text(
                                    '回复',
                                    style: TextStyle(
                                        fontSize: 11, color: AppTheme.textLightGray),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 格式化时间为相对时间描述
  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final diff = DateTime.now().difference(dateTime);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 30) return '${diff.inDays}天前';
      return '${dateTime.month}-${dateTime.day}';
    } catch (e) {
      return '';
    }
  }

  /// 显示更多操作菜单
  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示条
            Container(
              margin: EdgeInsets.only(top: 10, bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildMenuOption(
              icon: Icons.share_outlined,
              label: '分享',
              onTap: () {
                Get.back();
                ShareUtil.shareSong(Map<String, dynamic>.from(controller.music));
              },
            ),
            _buildMenuOption(
              icon: Icons.download_outlined,
              label: '下载',
              onTap: () {
                Get.back();
                _downloadSong(Get.context!);
              },
            ),
            _buildMenuOption(
              icon: Icons.playlist_add_rounded,
              label: '添加到歌单',
              onTap: () {
                Get.back();
                _showAddToPlaylistSheet(context);
              },
            ),
            _buildMenuOption(
              icon: Icons.flag_outlined,
              label: '举报',
              onTap: () {
                Get.back();
                _showReportDialog(Get.context!);
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 下载歌曲到本地
  void _downloadSong(BuildContext context) {
    final audioUrl = controller.music['audio_url'] ?? controller.music['url'] ?? '';
    if (audioUrl.isEmpty) {
      ToastUtil.showError('暂无音频文件可下载');
      return;
    }

    // 触发下载
    controller.downloadSong();

    // 显示下载进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Obx(() => Container(
          padding: EdgeInsets.all(AppTheme.spaceXl),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_rounded,
                  size: 40, color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text(
                controller.isDownloading.value ? '正在下载...' : '下载完成',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 16),
              // 进度条
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: controller.downloadProgress.value,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor),
                  minHeight: 6,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${(controller.downloadProgress.value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSilver,
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  /// 构建菜单选项
  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textWhite, size: 22),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示添加到歌单底部面板
  void _showAddToPlaylistSheet(BuildContext context) {
    controller.loadUserPlaylists();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示条
            Container(
              margin: EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '添加到歌单',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
            Container(
              height: 0.5,
              color: AppTheme.borderSubtle.withOpacity(0.3),
            ),
            // 歌单列表
            Obx(() {
              if (controller.isPlaylistsLoading.value) {
                return Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }
              if (controller.userPlaylists.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      '暂无歌单，快去创建一个吧~',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLightGray,
                      ),
                    ),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.userPlaylists.length,
                  itemBuilder: (_, index) {
                    final playlist = controller.userPlaylists[index];
                    final name = playlist['name'] ?? '未命名歌单';
                    final songCount = playlist['song_count'] ?? 0;
                    final cover = playlist['cover'] ?? playlist['cover_url'] ?? '';
                    return InkWell(
                      onTap: () => controller.addCurrentSongToPlaylist(
                          playlist['id'] as int),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            // 歌单封面
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: cover.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: cover,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          _buildPlaylistCoverPlaceholder(),
                                    )
                                  : _buildPlaylistCoverPlaceholder(),
                            ),
                            SizedBox(width: 12),
                            // 歌单名称 + 歌曲数
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppTheme.textWhite,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '$songCount首',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textLightGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 歌单封面占位图
  Widget _buildPlaylistCoverPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.music_note_rounded,
          size: 24, color: AppTheme.primaryColor),
    );
  }

  /// 举报原因选项列表
  static List<String> _reportReasons = [
    '不适当内容',
    '版权侵权',
    '垃圾信息',
    '其他',
  ];

  /// 显示举报原因选择对话框
  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(AppTheme.spaceXl),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '举报',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spaceLg),
              // 举报原因选项列表
              ...List.generate(_reportReasons.length, (index) {
                final reason = _reportReasons[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showReportDetailDialog(context, reason);
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 14, horizontal: 8),
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示举报详情输入对话框
  void _showReportDetailDialog(BuildContext context, String reason) {
    final detailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(AppTheme.spaceXl),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '举报 - $reason',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spaceLg),
              TextField(
                controller: detailController,
                maxLines: 3,
                style: TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: '请补充说明（选填）',
                  hintStyle: TextStyle(color: AppTheme.textDarkGray),
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusComfortable),
                    borderSide:
                        BorderSide(color: AppTheme.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusComfortable),
                    borderSide:
                        BorderSide(color: AppTheme.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusComfortable),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spaceXl),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppTheme.textWhite,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFullPill),
                          side:
                              BorderSide(color: AppTheme.borderGray),
                        ),
                      ),
                      child: Text('取消'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ToastUtil.success('举报已提交，我们会尽快处理');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.textWhite,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                      ),
                      child: Text('提交'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
