import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aimusic_app/modules/history/history_controller.dart';
import 'package:aimusic_app/services/api_service.dart';

/// 播放器控制器 - 增强版
/// 支持手势、进度拖动、3D音效、播放模式切换
class PlayerController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ===== 主题色预设 =====
  /// 预设主题色列表，根据歌曲ID取模选取
  static const List<Color> _themeColors = [
    Color(0xFF8E99A4), // 蓝灰
    Color(0xFFB0A898), // 暖灰
    Color(0xFFC4A0A0), // 柔粉
    Color(0xFF6BA3A0), // 青灰
    Color(0xFF7B9BB5), // 雾蓝
    Color(0xFF9C8F7A), // 暖棕
  ];

  // ===== Observable State =====
  final RxString _currentSongUrl = ''.obs;
  final RxString currentSongTitle = ''.obs;
  final RxString currentArtist = ''.obs;
  final RxString currentCoverUrl = ''.obs;
  final RxInt currentSongId = 0.obs;

  // ===== 播放队列 =====
  final RxList<Map<String, dynamic>> playList = <Map<String, dynamic>>[].obs;
  final RxInt currentIndex = (-1).obs;
  final RxBool _isPlaying = false.obs;
  final RxDouble _progress = 0.0.obs;
  final RxInt _duration = 0.obs;
  final RxInt _currentPosition = 0.obs;
  final RxBool _isLiked = false.obs;
  final RxBool _isShuffled = false.obs;
  final RxBool _isRepeating = false.obs;
  final RxDouble _playbackSpeed = 1.0.obs;
  final RxBool _isBuffering = false.obs;
  final RxBool showLyrics = false.obs;
  final RxInt currentLyricIndex = 0.obs;

  // ===== 睡眠定时器 =====
  /// 定时器总时长（秒），0 表示未设置
  final RxInt _sleepTimerDuration = 0.obs;
  /// 剩余时间（秒）
  final RxInt _sleepTimerRemaining = 0.obs;
  Timer? _sleepTimer;

  // ===== 均衡器 =====
  /// 当前均衡器预设名称
  final RxString _currentEqPreset = '标准'.obs;

  // ===== Getters =====
  bool get isPlaying => _isPlaying.value;
  double get progress => _progress.value;
  int get duration => _duration.value;
  int get currentPosition => _currentPosition.value;
  bool get isLiked => _isLiked.value;
  bool get isShuffled => _isShuffled.value;
  bool get isRepeating => _isRepeating.value;
  double get playbackSpeed => _playbackSpeed.value;
  bool get isBuffering => _isBuffering.value;
  int get sleepTimerRemaining => _sleepTimerRemaining.value;
  bool get isSleepTimerActive => _sleepTimerRemaining.value > 0;
  String get currentEqPreset => _currentEqPreset.value;

  /// 获取当前歌曲的主题色
  /// 根据播放队列索引从预设颜色列表中选取
  Color getThemeColor() {
    if (playList.isEmpty || currentIndex.value < 0) {
      return _themeColors[0]; // 默认返回靛蓝色
    }
    return _themeColors[currentIndex.value % _themeColors.length];
  }

  // ===== Lyric data =====
  final RxList<Map<String, dynamic>> lyrics = <Map<String, dynamic>>[].obs;

  // ===== 歌词滚动控制器 =====
  final ScrollController lyricScrollController = ScrollController();
  // 记录上一次滚动位置，避免重复动画
  int _lastScrolledIndex = -1;

  // ===== 逐字高亮：当前行中每个字的高亮进度 (0.0~1.0) =====
  final RxList<double> charProgress = <double>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initListener();
    // 从路由参数初始化歌曲
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      initWithSong(args);
    }
  }

  /// 用单首歌曲初始化播放（不设置播放队列）
  void initWithSong(Map<String, dynamic> song) {
    _applySong(song);
  }

  /// 设置播放队列并从指定索引开始播放
  void setPlayListAndPlay(List<Map<String, dynamic>> list, int index) {
    playList.value = list;
    currentIndex.value = index;
    _applySong(list[index]);
  }

  /// 将歌曲信息应用到当前状态并开始播放
  void _applySong(Map<String, dynamic> song) {
    _currentSongUrl.value = song['audio_url'] ?? '';
    currentSongTitle.value = song['title'] ?? '';
    currentArtist.value = song['singer'] ?? song['artist'] ?? '';
    currentCoverUrl.value = song['cover'] ?? song['cover_url'] ?? '';
    currentSongId.value = song['id'] ?? 0;
    play();
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
      debugPrint('记录播放历史失败: $e');
    }
  }

  /// 从歌曲详情 API 加载真实歌词
  void loadLyrics(List<Map<String, dynamic>> songLyrics) {
    if (songLyrics.isNotEmpty) {
      lyrics.value = songLyrics;
    } else {
      // 无歌词时留空，UI 层显示占位提示
      lyrics.value = [{'time': 0, 'text': '暂无歌词'}, {'time': 999999, 'text': ''}];
    }
  }

  void _initListener() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying.value = state == PlayerState.playing;
      // playing 时结束缓冲，其他状态保持
      if (state == PlayerState.playing) {
        _isBuffering.value = false;
      } else if (state == PlayerState.stopped || state == PlayerState.completed) {
        _isBuffering.value = false;
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition.value = position.inMilliseconds;
      if (_duration.value > 0) {
        _progress.value = _currentPosition.value / _duration.value;
      }
      // 更新歌词索引
      _updateLyricIndex();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _duration.value = duration.inMilliseconds;
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying.value = false;
      _progress.value = 0;
      _currentPosition.value = 0;
      if (_isRepeating.value) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.resume();
      } else {
        // 单曲播放完毕，自动播放下一首
        playNext();
      }
    });
  }

  void _updateLyricIndex() {
    final pos = _currentPosition.value;
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (pos >= (lyrics[i]['time'] as int)) {
        if (currentLyricIndex.value != i) {
          currentLyricIndex.value = i;
          _scrollToCurrentLyric(i);
        }
        // 计算当前行的逐字高亮进度
        _updateCharProgress(i, pos);
        return;
      }
    }
    if (currentLyricIndex.value != 0) {
      currentLyricIndex.value = 0;
      _scrollToCurrentLyric(0);
    }
    _updateCharProgress(0, pos);
  }

  /// 计算当前歌词行中每个字的高亮进度
  /// [lineIndex] 当前行索引
  /// [pos] 当前播放位置（毫秒）
  void _updateCharProgress(int lineIndex, int pos) {
    final text = lyrics[lineIndex]['text'] as String? ?? '';
    if (text.isEmpty) {
      charProgress.value = [];
      return;
    }

    // 当前行开始时间
    final lineStart = lyrics[lineIndex]['time'] as int;
    // 下一行开始时间（用于计算当前行持续时长）
    final lineEnd = lineIndex + 1 < lyrics.length
        ? (lyrics[lineIndex + 1]['time'] as int)
        : lineStart + 5000; // 最后一行默认5秒

    final lineDuration = lineEnd - lineStart;
    final elapsed = pos - lineStart;
    // 整行进度 0.0~1.0
    final lineProgress = lineDuration > 0
        ? (elapsed / lineDuration).clamp(0.0, 1.0)
        : 0.0;

    // 将进度均匀分配到每个字符
    final chars = text.characters.toList();
    final charCount = chars.length;
    final newProgress = List<double>.generate(charCount, (i) {
      // 每个字符的阈值：第 i 个字符在 i/charCount ~ (i+1)/charCount 之间
      final charStart = i / charCount;
      if (lineProgress <= charStart) return 0.0;
      final charEnd = (i + 1) / charCount;
      if (lineProgress >= charEnd) return 1.0;
      // 当前字符内的渐进进度
      return ((lineProgress - charStart) / (charEnd - charStart)).clamp(0.0, 1.0);
    });

    charProgress.value = newProgress;
  }

  /// 自动滚动到当前歌词行
  void _scrollToCurrentLyric(int index) {
    // 避免重复滚动同一行
    if (_lastScrolledIndex == index) return;
    _lastScrolledIndex = index;

    // 延迟执行，确保 ListView 已更新
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!lyricScrollController.hasClients) return;

      // 估算每行高度约 50px，目标位置居中
      const double itemHeight = 50.0;
      final double viewportHeight = lyricScrollController.position.viewportDimension;
      final double targetOffset = (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);

      // 限制在有效范围内
      final double maxScroll = lyricScrollController.position.maxScrollExtent;
      final double clampedOffset = targetOffset.clamp(0.0, maxScroll);

      lyricScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // ===== Playback Controls =====
  void play() {
    if (_currentSongUrl.value.isEmpty) return;
    _audioPlayer.play(UrlSource(_currentSongUrl.value));
  }

  void pause() => _audioPlayer.pause();
  void resume() => _audioPlayer.resume();

  void togglePlay() {
    if (_isPlaying.value) {
      pause();
    } else {
      resume();
    }
  }

  /// 播放上一首（第一首循环到最后一首）
  void playPrevious() {
    if (playList.isEmpty) return;
    int newIndex = currentIndex.value - 1;
    if (newIndex < 0) newIndex = playList.length - 1;
    currentIndex.value = newIndex;
    _applySong(playList[newIndex]);
  }

  /// 播放下一首（最后一首循环到第一首）
  void playNext() {
    if (playList.isEmpty) return;
    int newIndex = currentIndex.value + 1;
    if (newIndex >= playList.length) newIndex = 0;
    currentIndex.value = newIndex;
    _applySong(playList[newIndex]);
  }

  // 更新进度（拖动时）
  void seek(double ratio) {
    if (_duration.value <= 0) return;
    final position = Duration(milliseconds: (ratio * _duration.value).round());
    _audioPlayer.seek(position);
    _progress.value = ratio;
  }

  void seekForward({int seconds = 10}) {
    final newPos = (_currentPosition.value + seconds * 1000)
        .clamp(0, _duration.value);
    _audioPlayer.seek(Duration(milliseconds: newPos));
  }

  void seekBackward({int seconds = 10}) {
    final newPos = (_currentPosition.value - seconds * 1000)
        .clamp(0, _duration.value);
    _audioPlayer.seek(Duration(milliseconds: newPos));
  }

  // ===== Playback Modes =====
  /// 喜欢/取消喜欢当前歌曲，调用API并更新本地状态
  Future<void> toggleLike() async {
    final songId = currentSongId.value;
    if (songId == 0) return;
    try {
      final api = Get.find<ApiService>();
      final response = await api.post('/music/$songId/like');
      if (response['code'] == 0) {
        _isLiked.value = !_isLiked.value;
      }
    } catch (e) {
      debugPrint('切换喜欢状态失败: $e');
    }
  }

  void toggleShuffle() => _isShuffled.value = !_isShuffled.value;
  void toggleRepeat() => _isRepeating.value = !_isRepeating.value;

  void toggleLyrics() => showLyrics.value = !showLyrics.value;

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed.value = speed;
    await _audioPlayer.setPlaybackRate(speed);
  }

  List<double> getAvailableSpeeds() {
    return [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  }

  // ===== Formatting =====
  String get formattedPosition {
    return _formatDuration(_currentPosition.value);
  }

  String get formattedDuration {
    return _formatDuration(_duration.value);
  }

  String _formatDuration(int ms) {
    Duration d = Duration(milliseconds: ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  // ===== 睡眠定时器 =====
  /// 设置睡眠定时器，minutes 为 0 时取消
  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes == 0) {
      _sleepTimerDuration.value = 0;
      _sleepTimerRemaining.value = 0;
      return;
    }
    final seconds = minutes * 60;
    _sleepTimerDuration.value = seconds;
    _sleepTimerRemaining.value = seconds;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickSleepTimer());
  }

  /// 每秒倒计时，到时间自动暂停
  void _tickSleepTimer() {
    if (_sleepTimerRemaining.value <= 1) {
      _sleepTimer?.cancel();
      _sleepTimerRemaining.value = 0;
      _sleepTimerDuration.value = 0;
      pause();
      return;
    }
    _sleepTimerRemaining.value--;
  }

  /// 取消睡眠定时器
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerRemaining.value = 0;
    _sleepTimerDuration.value = 0;
  }

  /// 格式化剩余时间为 "mm:ss" 显示
  String get formattedSleepRemaining {
    final m = _sleepTimerRemaining.value ~/ 60;
    final s = _sleepTimerRemaining.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ===== 均衡器 =====
  /// 获取所有均衡器预设
  List<String> getEqPresets() {
    return ['标准', '流行', '摇滚', '古典', '爵士', '低音增强', '人声增强'];
  }

  /// 设置均衡器预设
  void setEqPreset(String preset) {
    _currentEqPreset.value = preset;
  }

  @override
  void onClose() {
    _sleepTimer?.cancel();
    lyricScrollController.dispose();
    _audioPlayer.dispose();
    super.onClose();
  }
}
