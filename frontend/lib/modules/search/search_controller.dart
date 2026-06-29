import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aimusic_app/services/api_service.dart';

class SearchController extends GetxController {
  final ApiService api = Get.find<ApiService>();

  final TextEditingController searchController = TextEditingController();

  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxMap searchResults = {}.obs;
  final RxList<String> searchHistory = <String>[].obs;

  /// 搜索历史存储键名
  static const String _historyKey = 'search_history';

  @override
  void onInit() {
    super.onInit();
    // 支持外部传入初始搜索关键词
    final initialQuery = Get.arguments;
    if (initialQuery is String && initialQuery.isNotEmpty) {
      searchController.text = initialQuery;
      searchQuery.value = initialQuery;
      // 延迟执行搜索，确保页面加载完成
      Future.microtask(() => performSearch());
    }
    loadSearchHistory();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    searchResults.clear();
  }

  Future<void> performSearch() async {
    if (searchQuery.value.trim().isEmpty) return;

    isSearching.value = true;
    try {
      final response = await api.get('/music/search', queryParameters: {
        'keyword': searchQuery.value,
      });

      if (response['code'] == 0) {
        searchResults.value = response['data'] ?? {};
        addToHistory(searchQuery.value);
      }
    } catch (e) {
      searchResults.value = {};
    } finally {
      isSearching.value = false;
    }
  }

  void searchFromHistory(String query) {
    searchController.text = query;
    searchQuery.value = query;
    performSearch();
  }

  /// 从 SharedPreferences 加载搜索历史
  Future<void> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey);
      if (list != null) {
        searchHistory.value = list;
      }
    } catch (e) {
      debugPrint('加载搜索历史失败: $e');
    }
  }

  /// 添加到搜索历史并持久化
  void addToHistory(String query) {
    if (searchHistory.contains(query)) {
      searchHistory.remove(query);
    }
    searchHistory.insert(0, query);
    if (searchHistory.length > 10) {
      searchHistory.removeLast();
    }
    _saveHistory();
  }

  /// 将搜索历史保存到 SharedPreferences
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_historyKey, searchHistory.toList());
    } catch (e) {
      debugPrint('保存搜索历史失败: $e');
    }
  }

  void clearHistory() {
    searchHistory.clear();
    _saveHistory();
  }

  void removeHistoryItem(String query) {
    searchHistory.remove(query);
    _saveHistory();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
