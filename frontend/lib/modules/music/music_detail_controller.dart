import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/services/playlist_service.dart';
import 'package:aimusic_app/utils/api_config.dart';
import 'package:aimusic_app/utils/toast_util.dart';

class MusicDetailController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final PlaylistService playlistService = Get.find<PlaylistService>();
  final RxMap music = {}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isLiked = false.obs;

  /// 评论列表
  final RxList<dynamic> comments = <dynamic>[].obs;
  /// 热评列表（点赞最多的评论）
  final RxList<dynamic> hotComments = <dynamic>[].obs;
  /// 评论输入控制器
  final TextEditingController commentController = TextEditingController();
  /// 评论防重复提交
  final RxBool isCommenting = false.obs;
  /// 用户歌单列表
  final RxList<dynamic> userPlaylists = <dynamic>[].obs;
  /// 歌单加载状态
  final RxBool isPlaylistsLoading = false.obs;

  /// 下载进度 (0.0 ~ 1.0)
  final RxDouble downloadProgress = 0.0.obs;
  /// 是否正在下载
  final RxBool isDownloading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final musicId = Get.arguments;
    if (musicId != null) {
      // 处理可能来自JSON的num/String类型，转换为int
      final int id = musicId is int 
          ? musicId 
          : musicId is String 
              ? int.parse(musicId) 
              : (musicId as num).toInt();
      loadDetail(id);
      checkIfLiked(id);
      loadComments(id);
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  Future<void> loadDetail(int musicId) async {
    isLoading.value = true;
    try {
      final response = await api.get('/music/$musicId');
      if (response['code'] == 0) {
        music.value = response['data'];
      }
    } catch (e) {
      debugPrint('加载歌曲详情失败');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkIfLiked(int musicId) async {
    // 喜欢状态通过 toggle 操作自动维护，无需单独查询
    // 如果歌曲详情中包含 is_liked 字段，可以从详情中获取
    try {
      final songLiked = music['is_liked'];
      if (songLiked != null) {
        isLiked.value = songLiked == true || songLiked == 1;
      }
    } catch (e) {
      // 忽略
    }
  }

  Future<void> toggleLike() async {
    try {
      final musicId = music['id'];
      if (musicId == null) return;
      
      final response = await api.post('/music/$musicId/like');
      if (response['code'] == 0) {
        isLiked.value = !isLiked.value;
        ToastUtil.showSuccess(
          isLiked.value ? '歌曲已添加到我喜欢的音乐' : '歌曲已从我喜欢的音乐中移除',
        );
      }
    } catch (e) {
      debugPrint('请稍后重试');
    }
  }

  /// 加载评论列表
  Future<void> loadComments(int songId) async {
    try {
      final response = await api.get('/music/$songId/comments');
      if (response['code'] == 0) {
        final list = response['data'] ?? [];
        comments.value = list;
        // 按点赞数降序排列，取前3条作为热评
        final sorted = List<dynamic>.from(list)
          ..sort((a, b) {
            final aLikes = a['like_count'] ?? 0;
            final bLikes = b['like_count'] ?? 0;
            return (bLikes as int).compareTo(aLikes as int);
          });
        hotComments.value = sorted.take(3).toList();
      }
    } catch (e) {
      // 评论加载失败静默处理
    }
  }

  /// 发送评论
  Future<void> addComment(String content) async {
    // 防重复提交：正在评论中则忽略
    if (isCommenting.value) return;

    if (content.trim().isEmpty) {
      ToastUtil.showWarning('评论内容不能为空');
      return;
    }
    try {
      isCommenting.value = true;
      final musicId = music['id'];
      if (musicId == null) return;

      final response = await api.post('/music/$musicId/comment', data: {
        'content': content.trim(),
      });
      if (response['code'] == 0) {
        commentController.clear();
        ToastUtil.showSuccess('你的评论已发布');
        // 刷新评论列表
        loadComments(musicId);
      } else {
        debugPrint(response['message'] ?? '请稍后重试');
      }
    } catch (e) {
      debugPrint('请稍后重试');
    } finally {
      isCommenting.value = false;
    }
  }

  /// 点赞/取消点赞评论
  Future<void> likeComment(dynamic comment) async {
    final commentId = comment['id'];
    if (commentId == null) return;
    try {
      final response = await api.post('/comment/$commentId/like');
      if (response['code'] == 0) {
        // 切换本地点赞状态
        final isLiked = comment['is_liked'] == true;
        comment['is_liked'] = !isLiked;
        comment['like_count'] = (comment['like_count'] ?? 0) + (isLiked ? -1 : 1);
        comments.refresh();
        hotComments.refresh();
      }
    } catch (e) {
      debugPrint('评论点赞失败: $e');
    }
  }

  /// 加载用户歌单列表（用于添加到歌单面板）
  Future<void> loadUserPlaylists() async {
    isPlaylistsLoading.value = true;
    try {
      final data = await playlistService.getUserPlaylists();
      if (data != null) {
        userPlaylists.value = data;
      }
    } catch (e) {
      // 静默处理
    } finally {
      isPlaylistsLoading.value = false;
    }
  }

  /// 添加当前歌曲到指定歌单
  Future<void> addCurrentSongToPlaylist(int playlistId) async {
    final musicId = music['id'];
    if (musicId == null) return;

    final success = await playlistService.addSongToPlaylist(
      playlistId: playlistId,
      songId: musicId is int ? musicId : (musicId as num).toInt(),
    );
    if (success) {
      Get.back(); // 关闭底部面板
    }
  }

  /// 下载当前歌曲到本地
  Future<void> downloadSong() async {
    final audioUrl = music['audio_url'] ?? music['url'] ?? '';
    if (audioUrl.isEmpty) {
      ToastUtil.showError('暂无音频文件可下载');
      return;
    }

    // 重置下载状态
    downloadProgress.value = 0.0;
    isDownloading.value = true;

    try {
      // 获取应用文档目录
      final dir = await getApplicationDocumentsDirectory();
      final title = music['title'] ?? 'song';
      final fileName = '${title}_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final savePath = '${dir.path}/$fileName';

      // 构建完整 URL
      String fullUrl = audioUrl;
      if (!audioUrl.startsWith('http')) {
        final base = ApiConfig.serverBaseUrl;
        fullUrl = '$base${audioUrl.startsWith('/') ? '' : '/'}$audioUrl';
      }

      final dio = Dio();
      await dio.download(
        fullUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress.value = received / total;
          }
        },
      );

      isDownloading.value = false;
      Get.back(); // 关闭对话框
      ToastUtil.success('已保存到本地');
    } catch (e) {
      isDownloading.value = false;
      Get.back();
      ToastUtil.showError('下载失败: $e');
    }
  }
}
