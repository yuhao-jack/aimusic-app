import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

/// 听歌报告控制器
/// 从播放历史API获取数据并统计本周听歌情况
class ListeningReportController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final RxBool isLoading = true.obs;

  /// 本周听歌总时长（毫秒）
  final RxInt totalListenMs = 0.obs;

  /// 本周听歌数量
  final RxInt songCount = 0.obs;

  /// 最常听的3首歌 [{title, artist, cover_url, play_count}]
  final RxList<Map<String, dynamic>> topSongs = <Map<String, dynamic>>[].obs;

  /// 最常听的风格标签
  final RxString topGenre = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadReport();
  }

  /// 加载听歌报告数据
  Future<void> loadReport() async {
    isLoading.value = true;
    try {
      final response = await _api.get('/history', queryParameters: {'limit': 200});
      if (response['code'] == 0) {
        final list = (response['data']['list'] as List?) ?? [];
        _analyzeData(list);
      }
    } catch (e) {
      debugPrint('加载听歌报告失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 分析播放历史数据
  void _analyzeData(List<dynamic> historyList) {
    final now = DateTime.now();
    // 本周一零点
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    // 筛选本周记录
    final thisWeek = historyList.where((item) {
      final ts = item['created_at'] ?? item['play_time'] ?? 0;
      final date = DateTime.fromMillisecondsSinceEpoch(
          ts is int ? ts : (ts is String ? int.tryParse(ts) ?? 0 : 0));
      return date.isAfter(weekStartDate);
    }).toList();

    // 统计听歌数量
    songCount.value = thisWeek.length;

    // 估算听歌时长（每首歌默认3分钟）
    totalListenMs.value = thisWeek.length * 3 * 60 * 1000;

    // 统计每首歌播放次数
    final Map<String, Map<String, dynamic>> songPlayCount = {};
    for (final item in thisWeek) {
      final songId = (item['song_id'] ?? item['id'] ?? '').toString();
      if (songPlayCount.containsKey(songId)) {
        songPlayCount[songId]!['play_count'] =
            (songPlayCount[songId]!['play_count'] as int) + 1;
      } else {
        songPlayCount[songId] = {
          'title': item['title'] ?? item['song_title'] ?? '未知歌曲',
          'artist': item['artist'] ?? item['singer'] ?? '未知歌手',
          'cover_url': item['cover_url'] ?? item['cover'] ?? '',
          'play_count': 1,
        };
      }
    }

    // 取播放次数最多的3首
    final sorted = songPlayCount.values.toList()
      ..sort((a, b) =>
          (b['play_count'] as int).compareTo(a['play_count'] as int));
    topSongs.value = sorted.take(3).toList();

    // 统计最常听的风格（从歌曲标签中提取）
    final Map<String, int> genreCount = {};
    for (final item in thisWeek) {
      final genre = item['genre'] ?? item['style'] ?? item['tag'] ?? '';
      if (genre.toString().isNotEmpty) {
        genreCount[genre.toString()] = (genreCount[genre.toString()] ?? 0) + 1;
      }
    }
    if (genreCount.isNotEmpty) {
      final sortedGenres = genreCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topGenre.value = sortedGenres.first.key;
    } else {
      topGenre.value = '流行';
    }
  }

  /// 格式化听歌时长为"x小时x分钟"
  String get formattedDuration {
    final minutes = totalListenMs.value ~/ 60000;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '$hours小时${mins > 0 ? '$mins分钟' : ''}';
    }
    return '$mins分钟';
  }
}
