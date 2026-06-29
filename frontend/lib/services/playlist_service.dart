import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:aimusic_app/services/api_service.dart';

class PlaylistService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  /// 获取推荐歌单
  Future<List<dynamic>?> getRecommendPlaylists() async {
    try {
      final response = await _api.get('/playlist/recommend');
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取推荐歌单失败: $e');
    }
    return null;
  }

  // 获取用户歌单列表
  Future<List<dynamic>?> getUserPlaylists() async {
    try {
      final response = await _api.get('/playlist/list');
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取歌单列表失败: $e');
    }
    return null;
  }

  // 创建歌单
  Future<bool> createPlaylist({
    required String name,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
      };
      if (description != null) data['description'] = description;

      final response = await _api.post('/playlist/create', data: data);
      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('创建歌单失败: $e');
      return false;
    }
  }

  // 更新歌单
  Future<bool> updatePlaylist({
    required int id,
    String? name,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;

      final response = await _api.put('/playlist/$id', data: data);
      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('更新歌单失败: $e');
      return false;
    }
  }

  // 删除歌单
  Future<bool> deletePlaylist(int id) async {
    try {
      final response = await _api.delete('/playlist/$id');
      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('删除歌单失败: $e');
      return false;
    }
  }

  // 添加歌曲到歌单
  Future<bool> addSongToPlaylist({
    required int playlistId,
    required int songId,
  }) async {
    try {
      final response = await _api.post('/playlist/$playlistId/add', data: {'song_id': songId});
      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('添加歌曲到歌单失败: $e');
      return false;
    }
  }

  // 从歌单移除歌曲
  Future<bool> removeSongFromPlaylist({
    required int playlistId,
    required int songId,
  }) async {
    try {
      final response = await _api.delete('/playlist/$playlistId/song/$songId');
      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('从歌单移除歌曲失败: $e');
      return false;
    }
  }
}
