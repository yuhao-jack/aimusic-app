import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/services/post_service.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/image_viewer.dart';

/// 动态详情页
class PostDetailPage extends StatefulWidget {
  final int postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = Get.find<PostService>();
  Map<String, dynamic>? _post;
  List<dynamic> _comments = [];
  bool _isLoading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final postData = await _postService.getPostDetail(widget.postId);
      final commentsData = await _postService.getPostComments(widget.postId);
      if (mounted) {
        setState(() {
          _post = postData;
          _comments = commentsData ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: const Text('动态详情', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
        )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.surface1,
        leading: IconButton(
          icon: Icon(textWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.brandIndigo, strokeWidth: 2))
          : _post == null
              ? const Center(child: Text('动态不存在', style: TextStyle(color: AppTheme.textSilver)))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPostHeader(),
                            const SizedBox(height: 16),
                            _buildPostContent(),
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 16),
                            _buildCommentSection(),
                          ],
                        ),
                      ),
                    ),
                    _buildCommentInput(),
                  ],
                ),
    );
  }

  Widget _buildPostHeader() {
    final nickname = _post!['nickname'] ?? _post!['username'] ?? '用户';
    final avatar = _post!['avatar'] ?? '';
    final createdAt = _post!['created_at'] ?? '';

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.surface2,
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar.isEmpty
              ? Icon(textLightGray)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nickname, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
              )),
              const SizedBox(height: 2),
              Text(_formatTime(createdAt), style: const TextStyle(
                fontSize: 12, color: AppTheme.textLightGray,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent() {
    final content = _post!['content'] ?? '';
    final images = _post!['images'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.isNotEmpty)
          Text(content, style: const TextStyle(
            fontSize: 16, color: AppTheme.textWhite, height: 1.6,
          )),
        if (images != null) ...[
          const SizedBox(height: 12),
          _buildImageGrid(images),
        ],
        const SizedBox(height: 16),
        _buildActionBar(),
      ],
    );
  }

  Widget _buildImageGrid(dynamic images) {
    List<String> imageUrls = [];
    if (images is List) {
      imageUrls = images.map((e) => e.toString()).toList();
    } else if (images is String && images.isNotEmpty && images != 'null') {
      try {
        imageUrls = List<String>.from(
          images.startsWith('[') ? List.from(JsonDecoder().convert(images)) : [images],
        );
      } catch (_) {
        imageUrls = [images];
      }
    }
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => showImageViewer(imageUrls: imageUrls, initialIndex: 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrls[0],
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              height: 220, color: AppTheme.surface2,
              child: Icon(textDarkGray),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(imageUrls.length.clamp(0, 9), (i) {
        return GestureDetector(
          onTap: () => showImageViewer(imageUrls: imageUrls, initialIndex: i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrls[i],
              width: 110, height: 110, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 110, height: 110, color: AppTheme.surface2,
                child: Icon(textDarkGray),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionBar() {
    final likeCount = _post!['like_count'] ?? 0;
    final commentCount = _post!['comment_count'] ?? 0;

    return Row(
      children: [
        _buildAction(Icons.favorite_border_rounded, '$likeCount', () {}),
        const SizedBox(width: 24),
        _buildAction(Icons.chat_bubble_outline_rounded, '$commentCount', () {}),
        const SizedBox(width: 24),
        _buildAction(Icons.share_outlined, '分享', () {
          Clipboard.setData(ClipboardData(text: 'https://aimusic.app/post/${_post!['id']}'));
          ToastUtil.showSuccess('链接已复制');
        }),
        const Spacer(),
        GestureDetector(
          onTap: _showMoreMenu,
          child: Icon(Icons.more_horiz_rounded, size: 20, color: AppTheme.textLightGray),
        ),
      ],
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textLightGray),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(textLightGray)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 0.5, color: AppTheme.borderSubtle.withValues(alpha: 0.3));
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('评论 (${_comments.length})', style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
        )),
        const SizedBox(height: 12),
        if (_comments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('暂无评论，快来抢沙发吧', style: TextStyle(
                color: AppTheme.textLightGray, fontSize: 14,
              )),
            ),
          )
        else
          ...List.generate(_comments.length, (i) => _buildCommentItem(_comments[i])),
      ],
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    final nickname = comment['user_nickname'] ?? comment['nickname'] ?? '用户';
    final avatar = comment['user_avatar'] ?? comment['avatar'] ?? '';
    final content = comment['content'] ?? '';
    final createdAt = comment['created_at'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.surface2,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? Icon(textLightGray)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(nickname, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
                    )),
                    const Spacer(),
                    Text(_formatTime(createdAt), style: const TextStyle(
                      fontSize: 11, color: AppTheme.textLightGray,
                    )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSilver, height: 1.4,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface2,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface3.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _commentController,
                style: TextStyle(textWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '写下你的评论...',
                  hintStyle: TextStyle(color: AppTheme.textDarkGray.withValues(alpha: 0.6), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendComment,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.brandIndigo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(textWhite),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final success = await _postService.addPostComment(
      postId: widget.postId,
      content: content,
    );
    if (success) {
      _commentController.clear();
      ToastUtil.showSuccess('评论成功');
      _loadData();
    } else {
      ToastUtil.showError('评论失败');
    }
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}-${dt.day}';
    } catch (_) {
      return timeStr;
    }
  }

  /// 显示更多操作菜单
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示条
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textDarkGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppTheme.textWhite),
              title: const Text('举报', style: TextStyle(color: AppTheme.textWhite)),
              onTap: () {
                Navigator.pop(ctx);
                _showReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.textLightGray),
              title: const Text('取消', style: TextStyle(color: AppTheme.textLightGray)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示举报原因选择对话框
  void _showReportDialog() {
    final reasons = ['垃圾广告', '色情低俗', '政治敏感', '人身攻击', '违法信息', '其他'];
    String selectedReason = reasons.first;
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppTheme.surface2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('举报', style: TextStyle(
            color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w600,
          )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请选择举报原因:', style: TextStyle(
                color: AppTheme.textSilver, fontSize: 14,
              )),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reasons.map((r) {
                  final isSelected = r == selectedReason;
                  return GestureDetector(
                    onTap: () => setState(() => selectedReason = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.brandIndigo : AppTheme.surface3,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.brandIndigo : AppTheme.borderSubtle,
                        ),
                      ),
                      child: Text(r, style: TextStyle(
                        color: isSelected ? AppTheme.textWhite : AppTheme.textSilver,
                        fontSize: 13,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface3.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: descController,
                  maxLines: 3,
                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '补充说明（可选）',
                    hintStyle: TextStyle(
                      color: AppTheme.textDarkGray.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: AppTheme.textLightGray)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _submitReport(selectedReason, descController.text.trim());
              },
              child: const Text('提交举报', style: TextStyle(color: AppTheme.brandIndigo)),
            ),
          ],
        ),
      ),
    );
  }

  /// 提交举报
  Future<void> _submitReport(String reason, String description) async {
    final success = await _postService.report(
      targetType: 'post',
      targetId: widget.postId,
      reason: reason,
      description: description,
    );
    if (success) {
      ToastUtil.showSuccess('举报成功，我们会尽快处理');
    } else {
      ToastUtil.showError('举报失败，请重试');
    }
  }
}
