import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:aimusic_app/services/music_service.dart';
import 'package:aimusic_app/services/playlist_service.dart';
import 'package:aimusic_app/modules/onboarding/onboarding_controller.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;

  final MusicService _musicService = Get.find<MusicService>();
  final PlaylistService _playlistService = Get.find<PlaylistService>();

  /// 用户偏好（从本地存储读取）
  List<String> _preferredGenres = [];
  List<String> _preferredMoods = [];

  // ========== 推荐页数据 ==========
  final RxList _songs = <dynamic>[].obs;
  final RxList _playlists = <dynamic>[].obs;
  final RxList _dailyRecommend = <dynamic>[].obs;
  final RxList _hotCharts = <dynamic>[].obs;
  final RxList _banners = <dynamic>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;

  List get songs => _songs.toList();
  List get playlists => _playlists.toList();
  List get dailyRecommend => _dailyRecommend.toList();
  List get hotCharts => _hotCharts.toList();
  List get banners => _banners.toList();

  // ========== 推荐歌曲分页状态 ==========
  static const int _pageSize = 20;
  int _currentPage = 1;
  final RxBool hasMore = true.obs;
  final RxBool isLoadingMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserPreferences();
    loadAllData();
  }

  /// 从本地存储加载用户偏好
  void _loadUserPreferences() {
    final prefs = OnboardingController.getUserPreferences();
    if (prefs != null) {
      _preferredGenres = List<String>.from(prefs['genres'] ?? []);
      _preferredMoods = List<String>.from(prefs['moods'] ?? []);
      debugPrint('加载用户偏好: genres=$_preferredGenres, moods=$_preferredMoods');
    }
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  /// 并行加载首页所有数据
  Future<void> loadAllData() async {
    isLoading.value = true;
    try {
      // 使用5分钟缓存
      const cache = Duration(minutes: 5);
      await Future.wait([
        _loadRecommendSongs(cacheDuration: cache),
        _loadPlaylists(),
        _loadDailyRecommend(cacheDuration: cache),
        _loadHotCharts(cacheDuration: cache),
        _loadBanners(),
      ]);
    } catch (e) {
      debugPrint('首页数据加载部分失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新所有数据（下拉刷新时使用），重置分页状态
  Future<void> refreshAll() async {
    isRefreshing.value = true;
    _currentPage = 1;
    hasMore.value = true;
    await loadAllData();
    isRefreshing.value = false;
  }

  /// 加载推荐歌曲（首页初始化，第一页）
  Future<void> _loadRecommendSongs({Duration? cacheDuration}) async {
    try {
      _currentPage = 1;
      final data = await _musicService.getRecommendSongs(
        page: _currentPage,
        pageSize: _pageSize,
        cacheDuration: cacheDuration,
      );
      final list = data ?? [];
      _songs.value = list;
      // 返回数据少于 pageSize 说明没有更多
      hasMore.value = list.length >= _pageSize;
    } catch (e) {
      debugPrint('加载推荐歌曲失败: $e');
    }
  }

  /// 加载更多推荐歌曲（滚动到底部时调用）
  Future<void> loadMoreSongs() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      _currentPage++;
      final data = await _musicService.getRecommendSongs(
        page: _currentPage,
        pageSize: _pageSize,
      );
      final list = data ?? [];
      if (list.isEmpty) {
        hasMore.value = false;
      } else {
        _songs.addAll(list);
        hasMore.value = list.length >= _pageSize;
      }
    } catch (e) {
      debugPrint('加载更多推荐歌曲失败: $e');
      _currentPage--; // 回退页码，下次重试
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      // 优先加载精选歌单，无数据时回退到推荐歌单
      var data = await _playlistService.getFeaturedPlaylists();
      if (data == null || data.isEmpty) {
        data = await _playlistService.getRecommendPlaylists();
      }
      _playlists.value = data ?? [];
    } catch (e) {
      debugPrint('加载歌单失败: $e');
    }
  }

  Future<void> _loadDailyRecommend({Duration? cacheDuration}) async {
    try {
      final data = await _musicService.getDailyRecommend(cacheDuration: cacheDuration);
      _dailyRecommend.value = data ?? [];
    } catch (e) {
      debugPrint('加载每日推荐失败: $e');
    }
  }

  Future<void> _loadHotCharts({Duration? cacheDuration}) async {
    try {
      final data = await _musicService.getHotCharts(cacheDuration: cacheDuration);
      _hotCharts.value = data ?? [];
    } catch (e) {
      debugPrint('加载热门榜单失败: $e');
    }
  }

  Future<void> _loadBanners() async {
    try {
      final data = await _musicService.getBanners();
      _banners.value = data ?? [];
    } catch (e) {
      // 接口不存在时静默处理，banner列表为空时UI不显示banner区域
    }
  }
}
