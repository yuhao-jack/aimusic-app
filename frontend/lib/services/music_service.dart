import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

class MusicService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  /// 获取推荐歌曲（支持分页和缓存）
  /// [genres] 用户偏好的音乐风格列表，用于个性化推荐
  /// [moods] 用户偏好的心情列表，用于个性化推荐
  Future<List<dynamic>?> getRecommendSongs({
    int page = 1,
    int pageSize = 20,
    Duration? cacheDuration,
    List<String>? genres,
    List<String>? moods,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      // 传入用户偏好参数，实现个性化推荐
      if (genres != null && genres.isNotEmpty) {
        queryParams['genres'] = genres.join(',');
      }
      if (moods != null && moods.isNotEmpty) {
        queryParams['moods'] = moods.join(',');
      }
      final response = await _api.get(
        '/music/recommend',
        queryParameters: queryParams,
        cacheDuration: cacheDuration,
      );
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取推荐歌曲失败: $e');
    }
    return null;
  }

  /// 获取每日推荐
  Future<List<dynamic>?> getDailyRecommend({Duration? cacheDuration}) async {
    try {
      final response = await _api.get('/music/daily-recommend', cacheDuration: cacheDuration);
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取每日推荐失败: $e');
    }
    return null;
  }

  /// 获取热门榜单
  Future<List<dynamic>?> getHotCharts({Duration? cacheDuration}) async {
    try {
      final response = await _api.get('/music/charts', cacheDuration: cacheDuration);
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取热门榜单失败: $e');
    }
    return null;
  }

  /// 获取首页 Banner 列表
  Future<List<dynamic>?> getBanners() async {
    try {
      final response = await _api.get('/music/banners');
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取Banner失败: $e');
    }
    return null;
  }

  // 获取排行榜歌曲
  Future<List<dynamic>?> getRankSongs(String type) async {
    try {
      final response = await _api.get('/music/rank/$type');
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取排行榜歌曲失败: $e');
    }
    return null;
  }

  // 搜索歌曲
  Future<List<dynamic>?> searchSongs(String keyword) async {
    try {
      final response = await _api.get('/music/search', queryParameters: {
        'keyword': keyword,
      });
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('搜索歌曲失败: $e');
    }
    return null;
  }

  // 获取歌曲详情
  Future<Map<String, dynamic>?> getSongDetail(int songId) async {
    try {
      final response = await _api.get('/music/$songId');
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取歌曲详情失败: $e');
    }
    return null;
  }

  // 增加播放次数
  Future<bool> incrementPlayCount(int songId) async {
    try {
      final response = await _api.post('/music/$songId/play');
      return response['code'] == 0;
    } catch (e) {
      debugPrint('增加播放次数失败: $e');
      return false;
    }
  }

  // 喜欢/取消喜欢歌曲
  Future<bool> likeSong(int songId) async {
    try {
      final response = await _api.post('/music/$songId/like');
      return response['code'] == 0;
    } catch (e) {
      debugPrint('喜欢歌曲失败: $e');
      return false;
    }
  }

  // 添加评论
  Future<bool> addComment(int songId, String content) async {
    try {
      final response = await _api.post('/music/$songId/comment', data: {
        'content': content,
      });
      return response['code'] == 0;
    } catch (e) {
      debugPrint('添加评论失败: $e');
      return false;
    }
  }

  // 获取歌曲评论
  Future<List<dynamic>?> getSongComments(int songId) async {
    try {
      final response = await _api.get('/music/$songId/comments');
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取歌曲评论失败: $e');
    }
    return null;
  }
}
