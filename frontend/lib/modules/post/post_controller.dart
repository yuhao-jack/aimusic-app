import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/toast_util.dart';

class PostController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final scrollController = ScrollController();

  RxList postList = [].obs;
  RxBool isLoading = false.obs;
  RxBool hasMore = true.obs;
  RxBool isCommenting = false.obs; // 评论防重复提交
  int currentPage = 1;
  final int pageSize = 10;
  int currentUserId = 0;

  @override
  void onInit() {
    super.onInit();
    // 获取当前用户ID，实际从用户信息获取
    loadPosts();
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200 &&
        !isLoading.value &&
        hasMore.value) {
      loadMorePosts();
    }
  }

  Future<void> loadPosts() async {
    if (isLoading.value) return;
    isLoading.value = true;
    currentPage = 1;

    try {
      final response = await api.get('/post/list', queryParameters: {
        'page': currentPage,
        'page_size': pageSize,
      });

      if (response['code'] == 0) {
        final data = response['data'];
        postList.value = data['list'];
        hasMore.value = postList.length >= data['page_size'];
      }
    } catch (e) {
      debugPrint('加载动态失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPosts() async {
    await loadPosts();
  }

  Future<void> loadMorePosts() async {
    if (isLoading.value || !hasMore.value) return;
    isLoading.value = true;
    currentPage++;

    try {
      final response = await api.get('/post/list', queryParameters: {
        'page': currentPage,
        'page_size': pageSize,
      });

      if (response['code'] == 0) {
        final data = response['data'];
        final newPosts = data['list'];
        postList.addAll(newPosts);
        hasMore.value = newPosts.length >= data['page_size'];
      }
    } catch (e) {
      debugPrint('加载更多失败: $e');
      currentPage--;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToCreatePost() async {
    final result = await Get.toNamed(AppRoutes.createPost);
    if (result == true) {
      loadPosts();
    }
  }

  Future<void> toggleLike(int postId) async {
    try {
      final response = await api.post('/post/$postId/like');
      if (response['code'] == 0) {
        final bool liked = response?['data']?['liked'] ?? false;
        final index = postList.indexWhere((p) => p['id'] == postId);
        if (index != -1) {
          postList[index]['is_liked'] = liked;
          if (liked) {
            postList[index]['like_count'] = (postList[index]['like_count'] ?? 0) + 1;
          } else {
            postList[index]['like_count'] = (postList[index]['like_count'] ?? 0) - 1;
          }
          postList.refresh();
        }
      }
    } catch (e) {
      debugPrint('操作失败: $e');
    }
  }

  Future<void> deletePost(int postId) async {
    final confirm = await Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条动态吗？删除后无法恢复'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await api.delete('/post/$postId');
      if (response['code'] == 0) {
        ToastUtil.showSuccess('删除成功');
        postList.removeWhere((p) => p['id'] == postId);
      } else {
        debugPrint(response['message'] ?? '删除失败');
      }
    } catch (e) {
      debugPrint('删除失败: $e');
    }
  }

  void openComments(post, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentBottomSheet(
        postId: post['id'],
        controller: this,
      ),
    );
  }

  Future<void> addComment(int postId, String content) async {
    // 防重复提交：正在评论中则忽略
    if (isCommenting.value) return;

    try {
      isCommenting.value = true;
      final response = await api.post('/post/$postId/comment', data: {
        'content': content,
        'parent_id': 0,
      });
      if (response['code'] == 0) {
        ToastUtil.showSuccess('评论成功');
        // 更新评论计数
        final index = postList.indexWhere((p) => p['id'] == postId);
        if (index != -1) {
          postList[index]['comment_count'] = (postList[index]['comment_count'] ?? 0) + 1;
          postList.refresh();
        }
      }
    } catch (e) {
      debugPrint('评论失败: $e');
    } finally {
      isCommenting.value = false;
    }
  }

  String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final date = DateTime.parse(timeStr);
      return DateFormat.yMd().add_jm().format(date);
    } catch (e) {
      return timeStr;
    }
  }
}

class CommentBottomSheet extends StatefulWidget {
  final int postId;
  final PostController controller;
  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.controller,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  RxList comments = [].obs;
  RxBool isLoading = false.obs;
  int currentPage = 1;
  final int pageSize = 20;

  @override
  void initState() {
    super.initState();
    loadComments();
  }

  Future<void> loadComments() async {
    isLoading.value = true;
    try {
      final response = await widget.controller.api.get(
        '/post/${widget.postId}/comments',
        queryParameters: {'page': currentPage, 'page_size': pageSize},
      );
      if (response['code'] == 0) {
        comments.value = response?['data']?['list'] ?? [];
      }
    } catch (e) {
      debugPrint('加载评论失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: const Color(0xFFFFFFFF).withOpacity(0.9),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: const Color(0xFF4B5563))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '评论',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(comment['user_nickname'] ?? '用户'),
                    subtitle: Text(comment['content'] ?? ''),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: const Color(0xFF4B5563))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '输入评论内容...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () async {
                    final content = _textController.text.trim();
                    if (content.isEmpty) return;
                    await widget.controller.addComment(widget.postId, content);
                    _textController.clear();
                    loadComments();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
