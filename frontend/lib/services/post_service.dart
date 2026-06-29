import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

class PostService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  // 创建动态
  Future<bool> createPost({
    required String content,
    List<String>? images,
    int? songId,
  }) async {
    try {
      final data = <String, dynamic>{
        'content': content,
      };
      if (images != null && images.isNotEmpty) data['images'] = images;
      if (songId != null) data['song_id'] = songId;

      final response = await _api.post('/post/create', data: data);
      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('创建动态失败: $e');
      return false;
    }
  }

  // 获取动态列表
  Future<List<dynamic>?> getPostList({
    int? page,
    int? pageSize,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (page != null) params['page'] = page;
      if (pageSize != null) params['page_size'] = pageSize;

      final response = await _api.get('/post/list', queryParameters: params);
      if (response['code'] == 0) {
        final data = response['data'];
        // 后端返回 {list: [...], total: ...} 格式
        if (data is Map && data['list'] is List) {
          return data['list'];
        }
        // 兼容直接返回数组的情况
        if (data is List) {
          return data;
        }
        return [];
      }
    } catch (e) {
      debugPrint('获取动态列表失败: $e');
    }
    return null;
  }

  // 获取用户动态列表
  Future<List<dynamic>?> getUserPostList(int userId) async {
    try {
      final response = await _api.get('/post/user/$userId');
      if (response['code'] == 0) {
        final data = response['data'];
        if (data is Map && data['list'] is List) return data['list'];
        if (data is List) return data;
        return [];
      }
    } catch (e) {
      debugPrint('获取用户动态列表失败: $e');
    }
    return null;
  }

  // 获取动态详情
  Future<Map<String, dynamic>?> getPostDetail(int postId) async {
    try {
      final response = await _api.get('/post/$postId');
      if (response['code'] == 0) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('获取动态详情失败: $e');
    }
    return null;
  }

  // 删除动态
  Future<bool> deletePost(int postId) async {
    try {
      final response = await _api.delete('/post/$postId');
      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('删除动态失败: $e');
      return false;
    }
  }

  // 点赞动态
  Future<bool> likePost(int postId) async {
    try {
      final response = await _api.post('/post/$postId/like');
      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('点赞动态失败: $e');
      return false;
    }
  }

  // 添加动态评论
  Future<bool> addPostComment({
    required int postId,
    required String content,
  }) async {
    try {
      final response = await _api.post('/post/$postId/comment', data: {
        'content': content,
      });
      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('添加动态评论失败: $e');
      return false;
    }
  }

  // 获取动态评论
  Future<List<dynamic>?> getPostComments(int postId) async {
    try {
      final response = await _api.get('/post/$postId/comments');
      if (response['code'] == 0) {
        final data = response['data'];
        if (data is Map && data['list'] is List) return data['list'];
        if (data is List) return data;
        return [];
      }
    } catch (e) {
      debugPrint('获取动态评论失败: $e');
    }
    return null;
  }

  // 删除动态评论
  Future<bool> deletePostComment(int commentId) async {
    try {
      final response = await _api.delete('/post/comment/$commentId');
      if (response['code'] == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('删除动态评论失败: $e');
      return false;
    }
  }

  // 举报接口
  // targetType: song/post/comment/user
  Future<bool> report({
    required String targetType,
    required int targetId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _api.post('/post/report', data: {
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        if (description != null && description.isNotEmpty)
          'description': description,
      });
      return response['code'] == 0;
    } catch (e) {
      debugPrint('举报失败: $e');
      return false;
    }
  }
}
