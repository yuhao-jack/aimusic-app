import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

class AIService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  // 生成歌词
  Future<Map<String, dynamic>?> generateLyric({
    required String prompt,
    String? style,
    String? emotion,
    String? lang,
  }) async {
    try {
      final data = <String, dynamic>{
        'prompt': prompt,
      };
      if (style != null) data['style'] = style;
      if (emotion != null) data['emotion'] = emotion;
      if (lang != null) data['lang'] = lang;

      final response = await _api.post('/ai/lyric/generate', data: data);
      // ApiService 返回 response.data（Dio 的 response.data），
      // 其中包含后端响应结构 {code, msg, data}
      if (response['code'] == 0) {
        return response['data'] as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('生成歌词失败: $e');
      return null;
    }
  }

  // 优化歌词
  Future<Map<String, dynamic>?> optimizeLyric({
    required String lyric,
    String? style,
  }) async {
    try {
      final data = <String, dynamic>{
        'lyric': lyric,
      };
      if (style != null) data['style'] = style;

      final response = await _api.post('/ai/lyric/optimize', data: data);
      if (response['code'] == 0) {
        return response['data'] as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('优化歌词失败: $e');
      return null;
    }
  }

  // 生成歌曲
  Future<Map<String, dynamic>?> generateSong({
    required String lyric,
    required String title,
    String? style,
    String? emotion,
    String? voiceId,
    int? duration,
  }) async {
    try {
      final data = <String, dynamic>{
        'lyric': lyric,
        'title': title,
      };
      if (style != null) data['style'] = style;
      if (emotion != null) data['emotion'] = emotion;
      if (voiceId != null) data['voice_id'] = voiceId;
      if (duration != null) data['duration'] = duration;

      final response = await _api.post('/ai/song/generate', data: data);
      if (response['code'] == 0) {
        return response['data'] as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('生成歌曲失败: $e');
      return null;
    }
  }

  // 获取任务进度
  Future<Map<String, dynamic>?> getTaskProgress(String taskId) async {
    try {
      final response = await _api.get('/ai/task/$taskId/progress');
      if (response['code'] == 0) {
        return response['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('获取任务进度失败: $e');
    }
    return null;
  }

  /// 获取公开系统配置（情绪、风格等），用于前端选项动态化
  Future<Map<String, dynamic>?> getPublicConfig() async {
    try {
      final response = await _api.get('/system/config');
      if (response['code'] == 0) {
        final data = response['data'];
        if (data is Map) {
          // 后端返回的 value 是 JSON 字符串，需要解析
          final result = <String, dynamic>{};
          data.forEach((key, value) {
            if (value is String && value.startsWith('[')) {
              try {
                result[key] = List<String>.from(
                  (const JsonDecoder().convert(value) as List).map((e) => e.toString()),
                );
              } catch (e) {
                debugPrint('解析配置JSON失败: $e');
                result[key] = value;
              }
            } else {
              result[key] = value;
            }
          });
          return result;
        }
      }
    } catch (e) {
      debugPrint('获取公开配置失败: $e');
    }
    return null;
  }
}
