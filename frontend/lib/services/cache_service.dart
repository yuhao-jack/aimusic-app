import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 缓存歌曲信息
class CachedSong {
  final int songId;
  final String title;
  final String singer;
  final String cover;
  final String localPath;
  final int fileSize;
  final DateTime cachedAt;

  CachedSong({
    required this.songId,
    required this.title,
    required this.singer,
    required this.cover,
    required this.localPath,
    required this.fileSize,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
        'song_id': songId,
        'title': title,
        'singer': singer,
        'cover': cover,
        'local_path': localPath,
        'file_size': fileSize,
        'cached_at': cachedAt.toIso8601String(),
      };

  factory CachedSong.fromJson(Map<String, dynamic> json) => CachedSong(
        songId: json['song_id'] ?? 0,
        title: json['title'] ?? '',
        singer: json['singer'] ?? '',
        cover: json['cover'] ?? '',
        localPath: json['local_path'] ?? '',
        fileSize: json['file_size'] ?? 0,
        cachedAt: DateTime.parse(json['cached_at']),
      );
}

/// 离线缓存服务
/// 管理歌曲的下载、缓存查看、删除和大小统计
class CacheService extends GetxService {
  static const String _cacheKey = 'cached_songs';

  /// 已缓存歌曲列表
  final RxList<CachedSong> cachedSongs = <CachedSong>[].obs;

  /// 缓存总大小（字节）
  final RxInt totalCacheSize = 0.obs;

  /// 下载进度（0.0 ~ 1.0）
  final RxDouble downloadProgress = 0.0.obs;

  /// 是否正在下载
  final RxBool isDownloading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCacheIndex();
  }

  /// 获取缓存目录
  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/song_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// 从本地加载缓存索引
  Future<void> _loadCacheIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr != null) {
        final List<dynamic> list = jsonDecode(jsonStr);
        cachedSongs.value = list.map((e) => CachedSong.fromJson(e)).toList();
        _calculateTotalSize();
      }
    } catch (e) {
      debugPrint('加载缓存索引失败: $e');
    }
  }

  /// 保存缓存索引到本地
  Future<void> _saveCacheIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(cachedSongs.map((e) => e.toJson()).toList());
      await prefs.setString(_cacheKey, jsonStr);
    } catch (e) {
      debugPrint('保存缓存索引失败: $e');
    }
  }

  /// 计算缓存总大小
  void _calculateTotalSize() {
    int total = 0;
    for (final song in cachedSongs) {
      total += song.fileSize;
    }
    totalCacheSize.value = total;
  }

  /// 检查歌曲是否已缓存
  bool isCached(int songId) {
    return cachedSongs.any((s) => s.songId == songId);
  }

  /// 获取缓存的本地路径
  String? getCachedPath(int songId) {
    try {
      final song = cachedSongs.firstWhere((s) => s.songId == songId);
      return song.localPath;
    } catch (_) {
      return null;
    }
  }

  /// 下载并缓存歌曲
  /// [songId] 歌曲ID
  /// [title] 歌曲标题
  /// [singer] 歌手
  /// [cover] 封面URL
  /// [audioUrl] 音频文件URL
  Future<bool> downloadSong({
    required int songId,
    required String title,
    required String singer,
    required String cover,
    required String audioUrl,
  }) async {
    if (isCached(songId)) {
      debugPrint('歌曲已缓存: $title');
      return true;
    }

    if (isDownloading.value) {
      debugPrint('已有下载任务进行中');
      return false;
    }

    try {
      isDownloading.value = true;
      downloadProgress.value = 0;

      final cacheDir = await _getCacheDir();
      final fileName = 'song_$songId.mp3';
      final filePath = '${cacheDir.path}/$fileName';

      // 下载文件
      final dio = Dio();
      await dio.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress.value = received / total;
          }
        },
      );

      // 获取文件大小
      final file = File(filePath);
      final fileSize = await file.length();

      // 添加到缓存列表
      final cachedSong = CachedSong(
        songId: songId,
        title: title,
        singer: singer,
        cover: cover,
        localPath: filePath,
        fileSize: fileSize,
        cachedAt: DateTime.now(),
      );

      cachedSongs.add(cachedSong);
      _calculateTotalSize();
      await _saveCacheIndex();

      debugPrint('歌曲缓存成功: $title (${_formatSize(fileSize)})');
      return true;
    } catch (e) {
      debugPrint('歌曲缓存失败: $e');
      return false;
    } finally {
      isDownloading.value = false;
      downloadProgress.value = 0;
    }
  }

  /// 删除指定歌曲缓存
  Future<void> deleteCache(int songId) async {
    try {
      final index = cachedSongs.indexWhere((s) => s.songId == songId);
      if (index == -1) return;

      final song = cachedSongs[index];
      final file = File(song.localPath);
      if (await file.exists()) {
        await file.delete();
      }

      cachedSongs.removeAt(index);
      _calculateTotalSize();
      await _saveCacheIndex();
      debugPrint('已删除缓存: ${song.title}');
    } catch (e) {
      debugPrint('删除缓存失败: $e');
    }
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    try {
      final cacheDir = await _getCacheDir();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      cachedSongs.clear();
      totalCacheSize.value = 0;
      await _saveCacheIndex();
      debugPrint('已清空所有缓存');
    } catch (e) {
      debugPrint('清空缓存失败: $e');
    }
  }

  /// 格式化文件大小
  static String formatSize(int bytes) => _formatSize(bytes);

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
