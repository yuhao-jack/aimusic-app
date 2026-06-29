import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aimusic_app/services/music_service.dart';
import 'package:aimusic_app/modules/history/history_controller.dart';

/// 私人FM控制器
/// 自动播放推荐歌曲，支持喜欢/跳过操作
class FmController extends GetxController {
  final MusicService _musicService = Get.find<MusicService>();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ===== 播放状态 =====
  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxString currentTitle = ''.obs;
  final RxString currentArtist = ''.obs;
  final RxString currentCoverUrl = ''.obs;
  final RxInt currentSongId = 0.obs;
  final RxBool isLiked = false.obs;

  // ===== 动画控制状态 =====
  /// 是否正在执行跳过动画
  final RxBool isSkipping = false.obs;
  /// 喜欢按钮弹跳触发器
  final RxInt likeBounceTrigger = 0.obs;

  // ===== 播放队列 =====
  final RxList<Map<String, dynamic>> songQueue = <Map<String, dynamic>>[].obs;
  final RxInt currentIndex = 0.obs;

  // ===== 进度 =====
  final RxDouble progress = 0.0.obs;
  final RxInt duration = 0.obs;
  final RxInt currentPosition = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initListeners();
    loadRecommendSongs();
  }

  /// 初始化音频播放器监听
  void _initListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      currentPosition.value = pos.inMilliseconds;
      if (duration.value > 0) {
        progress.value = currentPosition.value / duration.value;
      }
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      duration.value = dur.inMilliseconds;
    });

    // 播放完成时自动播放下一首
    _audioPlayer.onPlayerComplete.listen((_) {
      playNext();
    });
  }

  /// 加载推荐歌曲
  Future<void> loadRecommendSongs() async {
    isLoading.value = true;
    try {
      final songs = await _musicService.getRecommendSongs();
      if (songs != null && songs.isNotEmpty) {
        songQueue.value = List<Map<String, dynamic>>.from(songs);
        currentIndex.value = 0;
        _playCurrentSong();
      }
    } catch (e) {
      debugPrint('加载推荐歌曲失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 播放当前歌曲
  void _playCurrentSong() {
    if (songQueue.isEmpty || currentIndex.value >= songQueue.length) {
      // 队列播放完毕，重新加载
      loadRecommendSongs();
      return;
    }

    final song = songQueue[currentIndex.value];
    currentTitle.value = song['title'] ?? '';
    currentArtist.value = song['singer'] ?? song['artist'] ?? '未知歌手';
    currentCoverUrl.value = song['cover'] ?? song['cover_url'] ?? '';
    currentSongId.value = song['id'] ?? 0;
    // 重置喜欢状态
    isLiked.value = false;

    final audioUrl = song['audio_url'] ?? '';
    if (audioUrl.isNotEmpty) {
      _audioPlayer.play(UrlSource(audioUrl));
    }

    // 记录播放历史
    _recordHistory(song['id']);
  }

  /// 记录播放历史（静默失败，不影响播放）
  void _recordHistory(dynamic songId) {
    if (songId == null || songId == 0) return;
    try {
      if (Get.isRegistered<HistoryController>()) {
        Get.find<HistoryController>().addHistory(songId as int);
      }
    } catch (e) {
      debugPrint('FM记录播放历史失败: $e');
    }
  }

  /// 切换播放/暂停
  void togglePlay() {
    if (isPlaying.value) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  /// 播放下一首（跳过），带动画标记
  void playNext() {
    if (songQueue.isEmpty || isSkipping.value) return;

    isSkipping.value = true;
    currentIndex.value++;
    if (currentIndex.value >= songQueue.length) {
      // 队列播放完毕，重新加载
      loadRecommendSongs();
    } else {
      _playCurrentSong();
    }
    // 动画完成后重置标记（由页面层动画回调控制）
  }

  /// 重置跳过状态（由页面动画完成时调用）
  void resetSkipState() {
    isSkipping.value = false;
  }

  /// 喜欢当前歌曲
  Future<void> likeCurrentSong() async {
    if (currentSongId.value == 0) return;

    final success = await _musicService.likeSong(currentSongId.value);
    if (success) {
      isLiked.value = !isLiked.value;
      // 触发弹跳动画
      likeBounceTrigger.value++;
    }
  }

  /// 不喜欢（跳过并标记）
  void dislikeCurrentSong() {
    // 这里可以添加不喜欢逻辑，比如记录到后端
    playNext();
  }

  /// 获取当前歌曲数据（用于详情页）
  Map<String, dynamic>? get currentSongData {
    if (songQueue.isEmpty || currentIndex.value >= songQueue.length) {
      return null;
    }
    return songQueue[currentIndex.value];
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}