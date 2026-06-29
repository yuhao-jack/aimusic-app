import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/utils/http_util.dart';
import 'package:aimusic_app/utils/toast_util.dart';

class PlaylistController extends GetxController {
  final RxList playlistList = [].obs;
  final RxBool isLoading = false.obs;

  /// 创建歌单弹窗 - 是否公开
  final RxBool isPublicPlaylist = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlaylists();
  }

  Future<void> fetchPlaylists() async {
    isLoading.value = true;
    try {
      final response = await HttpUtil().get('/playlist/list');
      if (response.statusCode == 200 && response.data['code'] == 0) {
        final data = response.data['data'];
        if (data is Map && data['list'] is List) {
          playlistList.value = data['list'];
        } else if (data is List) {
          playlistList.value = data;
        }
      }
    } catch (e) {
      debugPrint('获取歌单失败');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createPlaylist(String name, {bool isPublic = false}) async {
    // 防重复提交：正在加载中则忽略
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      final response = await HttpUtil().post(
        '/playlist/create',
        data: {
          'name': name,
          'is_public': isPublic,
        },
      );
      if (response.statusCode == 200 && response.data['code'] == 0) {
        ToastUtil.showSuccess('创建成功');
        fetchPlaylists();
      } else {
        debugPrint(response.data['message'] ?? '创建失败');
      }
    } catch (e) {
      debugPrint('创建失败');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePlaylist(int playlistId) async {
    try {
      final response = await HttpUtil().delete('/playlist/$playlistId');
      if (response.statusCode == 200 && response.data['code'] == 0) {
        ToastUtil.showSuccess('删除成功');
        fetchPlaylists();
      }
    } catch (e) {
      debugPrint('删除失败');
    }
  }

  /// 点赞歌单
  Future<void> likePlaylist(int playlistId) async {
    try {
      final response = await HttpUtil().post('/playlist/$playlistId/like');
      if (response.statusCode == 200 && response.data['code'] == 0) {
        ToastUtil.showSuccess('点赞成功');
        fetchPlaylists();
      } else {
        final msg = response.data['message'] ?? '点赞失败';
        ToastUtil.showError(msg);
      }
    } catch (e) {
      debugPrint('点赞失败: $e');
      ToastUtil.showError('点赞失败');
    }
  }
}
