import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/search/search_controller.dart' as sc;
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

/// 搜索页面 - 带防抖、热词、历史记录、动画效果的丝滑体验
class SearchPage extends GetView<sc.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildSearchBar(),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: ElasticButton(
          onTap: () => Get.back(),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_rounded,
                  color: AppTheme.textWhite, size: 20),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final query = controller.searchQuery.value;
          if (query.isEmpty) {
            return _buildInitialView();
          } else if (controller.isSearching.value) {
            return _buildSearchLoading();
          } else if (controller.searchResults.isEmpty) {
            return _buildNoResults(query);
          } else {
            return _buildSearchResults();
          }
        }),
      ),
    );
  }

  // ==================== Search Bar (药丸形) ====================

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 44,
      child: TextField(
        controller: controller.searchController,
        autofocus: true,
        style: const TextStyle(
          color: AppTheme.textWhite,
          fontSize: 15,
        ),
        cursorColor: AppTheme.brandPurple,
        decoration: InputDecoration(
          hintText: '搜索歌曲、歌手、歌单',
          hintStyle: const TextStyle(color: AppTheme.textDim),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.search_rounded,
                color: AppTheme.textSilver, size: 22),
          ),
          suffixIcon: Obx(() =>
              controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textSilver, size: 20),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink()),
          filled: true,
          fillColor: AppTheme.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            borderSide: const BorderSide(
              color: AppTheme.brandPurple,
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onChanged: (value) {
          controller.updateSearchQuery(value);
        },
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            controller.performSearch();
          }
        },
      ),
    );
  }

  // ==================== Initial View (Hot Tags + History) ====================

  Widget _buildInitialView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fade in hot tags first
          FadeInWidget(
            delayMs: 60,
            child: _buildHotTagsSection(),
          ),
          const SizedBox(height: 32),
          // Fade in history section
          Obx(() {
            if (controller.searchHistory.isEmpty) {
              return _buildEmptyHint();
            }
            return FadeInWidget(
              delayMs: 180,
              child: _buildHistorySection(),
            );
          }),
        ],
      ),
    );
  }

  // ----- Hot Tags Section -----

  Widget _buildHotTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '热搜推荐',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSilver,
          ),
        ),
        const SizedBox(height: 12),
        _buildHotTags(),
      ],
    );
  }

  Widget _buildHotTags() {
    final hotTags = [
      '周杰伦', 'Taylor Swift', '流行', '说唱',
      '轻音乐', 'AI生成', '经典', '摇滚', '电音', 'R&B',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: hotTags.map((tag) {
        return ElasticButton(
          onTap: () {
            controller.searchController.text = tag;
            controller.updateSearchQuery(tag);
            controller.performSearch();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSilver,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ----- History Section -----

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '搜索历史',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSilver,
              ),
            ),
            ElasticButton(
              onTap: controller.clearHistory,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_sweep_outlined,
                    color: AppTheme.textDim, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...controller.searchHistory.map(
          (h) => _buildHistoryItem(h),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(String query) {
    return Dismissible(
      key: Key('search_history_$query'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.textWhite,
          size: 20,
        ),
      ),
      onDismissed: (_) => controller.removeHistoryItem(query),
      child: ElasticButton(
        onTap: () {
          controller.searchController.text = query;
          controller.updateSearchQuery(query);
          controller.performSearch();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: const Icon(
              Icons.history_rounded,
              color: AppTheme.textDim,
              size: 20,
            ),
            title: Text(
              query,
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 15,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textDim,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // ----- Empty Hint -----

  Widget _buildEmptyHint() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.search_rounded,
          size: 80,
          color: AppTheme.textDim.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        const Text(
          '搜索你喜欢的音乐',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSilver,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '发现海量AI音乐作品',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textDim,
          ),
        ),
      ],
    );
  }

  // ==================== Search Loading State ====================

  Widget _buildSearchLoading() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return FadeInWidget(
          delayMs: (index * 60).clamp(0, 300),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusComfortable),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface2,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== No Results ====================

  Widget _buildNoResults(String query) {
    return Center(
      child: FadeInWidget(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppTheme.textDarkGray.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              '没有找到「$query」相关歌曲',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSilver,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '试试其他关键词吧',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Search Results ====================

  Widget _buildSearchResults() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: controller.searchResults.length,
      itemBuilder: (context, index) {
        return FadeInWidget(
          delayMs: (index * 60).clamp(0, 500),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildResultItem(controller.searchResults[index] as Map),
          ),
        );
      },
    );
  }

  Widget _buildResultItem(Map item) {
    final title = item['title'] ?? '';
    final artist = item['artist'] ?? item['singer'] ?? '未知歌手';
    final cover = item['cover'] ?? item['cover_url'] ?? '';

    return ElasticButton(
      onTap: () => Get.toNamed(AppRoutes.musicDetail,
          arguments: item['id']),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius:
              BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: AppTheme.borderSubtle.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Cover image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: cover.isNotEmpty
                  ? Image.network(
                      cover,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: AppTheme.surface2,
                        child: const Icon(
                          Icons.music_note,
                          color: AppTheme.textDim,
                          size: 28,
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 60,
                          height: 60,
                          color: AppTheme.surface2,
                          child: const Icon(
                            Icons.music_note,
                            color: AppTheme.textDim,
                            size: 28,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.surface2,
                      child: const Icon(
                        Icons.music_note,
                        color: AppTheme.textDim,
                        size: 28,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Title and artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSilver,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Right arrow
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textDim,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
