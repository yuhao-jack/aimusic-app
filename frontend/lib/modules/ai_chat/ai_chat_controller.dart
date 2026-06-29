import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

/// AI对话推荐控制器
/// 维护聊天记录，调用AI服务获取音乐推荐
class AiChatController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  /// 聊天消息列表 [{role: 'user'|'ai', content: '...', songs: [...]}]
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  /// 是否正在等待AI回复
  final RxBool isLoading = false.obs;

  /// 预设快捷问题
  final List<String> quickQuestions = [
    '推荐一首轻松的歌',
    '适合运动的音乐',
    '帮我创建一个歌单',
    '推荐一些治愈系的歌',
    '适合深夜听的歌',
  ];

  /// 发送消息并获取AI回复
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // 添加用户消息
    messages.add({'role': 'user', 'content': content.trim()});
    isLoading.value = true;

    try {
      final response = await _api.post('/ai/chat/recommend', data: {
        'message': content.trim(),
      });

      if (response['code'] == 0) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final reply = data['reply'] ?? '抱歉，我暂时无法回答这个问题';
        final songs = (data['songs'] as List?) ?? [];

        messages.add({
          'role': 'ai',
          'content': reply,
          'songs': songs.map((s) => Map<String, dynamic>.from(s)).toList(),
        });
      } else {
        _addFallbackReply(content);
      }
    } catch (e) {
      debugPrint('AI对话请求失败: $e');
      _addFallbackReply(content);
    } finally {
      isLoading.value = false;
    }
  }

  /// 请求失败时的兜底回复
  void _addFallbackReply(String userMessage) {
    String reply;
    List<Map<String, dynamic>> songs = [];

    if (userMessage.contains('轻松') || userMessage.contains('放松')) {
      reply = '为你推荐几首轻松舒缓的歌曲，适合放松心情时聆听：';
      songs = [
        {'title': '晴天', 'artist': '周杰伦', 'id': 1},
        {'title': '小幸运', 'artist': '田馥甄', 'id': 2},
        {'title': '平凡之路', 'artist': '朴树', 'id': 3},
      ];
    } else if (userMessage.contains('运动') || userMessage.contains('健身')) {
      reply = '这些节奏感强的歌曲非常适合运动时听：';
      songs = [
        {'title': 'Fade', 'artist': 'Alan Walker', 'id': 4},
        {'title': 'Counting Stars', 'artist': 'OneRepublic', 'id': 5},
        {'title': 'Stronger', 'artist': 'Kelly Clarkson', 'id': 6},
      ];
    } else if (userMessage.contains('歌单') || userMessage.contains('创建')) {
      reply = '好的！你可以告诉我你想要什么风格的歌单，我会帮你推荐歌曲并创建。试试告诉我你的心情或场景～';
    } else if (userMessage.contains('治愈') || userMessage.contains('温暖')) {
      reply = '这些治愈系歌曲能温暖你的心：';
      songs = [
        {'title': '起风了', 'artist': '买辣椒也用券', 'id': 7},
        {'title': '光年之外', 'artist': '邓紫棋', 'id': 8},
        {'title': '后来', 'artist': '刘若英', 'id': 9},
      ];
    } else if (userMessage.contains('深夜') || userMessage.contains('夜晚')) {
      reply = '深夜适合听一些安静的歌曲，推荐这些：';
      songs = [
        {'title': '夜曲', 'artist': '周杰伦', 'id': 10},
        {'title': '安静', 'artist': '周杰伦', 'id': 11},
        {'title': '月半小夜曲', 'artist': '李克勤', 'id': 12},
      ];
    } else {
      reply = '我理解你在寻找好听的音乐。试试更具体地描述你的心情或场景，比如"推荐适合下雨天听的歌"，我能给出更好的推荐～';
    }

    messages.add({
      'role': 'ai',
      'content': reply,
      'songs': songs,
    });
  }

  /// 清空聊天记录
  void clearMessages() {
    messages.clear();
  }
}
