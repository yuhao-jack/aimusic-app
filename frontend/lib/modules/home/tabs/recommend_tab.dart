import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/utils/http_util.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/modules/home/home_controller.dart';
import 'package:aimusic_app/modules/create/create_page.dart';
import 'package:aimusic_app/utils/share_util.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

/// 推荐 Tab
/// 视觉风格：简约 + 毛玻璃 + 科技感
class RecommendTab extends StatefulWidget {
  RecommendTab({super.key});

  @override
  State<RecommendTab> createState() => _RecommendTabState();
}

class _RecommendTabState extends State<RecommendTab>
    with AutomaticKeepAliveClientMixin {
  final HomeController _controller = Get.find<HomeController>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (_controller.isLoading.value && _controller.songs.isEmpty) {
        _controller.loadAllData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _controller.refreshAll,
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.surface2,
      displacement: 80,
      edgeOffset: -40,
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          // ===== 固定头部：发现 + 通知 + 搜索 =====
          SliverAppBar(
            expandedHeight: 52,
            collapsedHeight: 52,
            pinned: true,
            floating: false,
            snap: false,
            backgroundColor: AppTheme.surface1,
            flexibleSpace: SafeArea(
              bottom: false,
              child: Container(
                height: 52,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '发现',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Spacer(),
                    // 通知按钮
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.notification),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.surface3,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // 搜索按钮
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.search),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.surface3,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== Content =====
          Obx(() {
            if (_controller.isLoading.value) {
              return SliverToBoxAdapter(
                child: RecommendTabShimmer(),
              );
            }

            final showDaily = _controller.dailyRecommend.isNotEmpty;
            final showHot = _controller.hotCharts.isNotEmpty;
            final showPlaylists = _controller.playlists.isNotEmpty;
            final showSongs = _controller.songs.isNotEmpty;

            return SliverToBoxAdapter(
              child: FadeInWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),

                    // ===== Banner =====
                    if (_controller.banners.isNotEmpty) ...[
                      _buildBannerCarousel(),
                      SizedBox(height: 24),
                    ],

                    // ===== Quick Actions =====
                    _buildQuickActions(),
                    SizedBox(height: 32),

                    // ===== Daily Recommend =====
                    if (showDaily) ...[
                      _buildSectionTitle('每日推荐'),
                      SizedBox(height: AppTheme.spaceSm),
                      _buildDailyRecommendSection(),
                      SizedBox(height: 28),
                    ],

                    // ===== 心情推荐 =====
                    _buildSectionTitle('心情推荐'),
                    SizedBox(height: AppTheme.spaceSm),
                    _buildMoodRecommendSection(),
                    SizedBox(height: 28),

                    // ===== 猜你喜欢 =====
                    _buildSectionTitle('猜你喜欢'),
                    SizedBox(height: AppTheme.spaceSm),
                    _buildGuessYouLikeSection(),
                    SizedBox(height: 28),

                    // ===== Hot Charts =====
                    if (showHot) ...[
                      _buildSectionTitle('热门榜单'),
                      SizedBox(height: AppTheme.spaceSm),
                      _buildHotChartSection(),
                      SizedBox(height: 28),
                    ],

                    // ===== Creator Stars =====
                    _buildSectionTitle('创作明星'),
                    SizedBox(height: AppTheme.spaceSm),
                    _buildCreatorStarsSection(),
                    SizedBox(height: 28),

                    // ===== Playlists =====
                    if (showPlaylists) ...[
                      _buildSectionTitle('精选歌单'),
                      SizedBox(height: AppTheme.spaceSm),
                      _buildPlaylistsSection(),
                      SizedBox(height: 28),
                    ],

                    // ===== Recommended Songs =====
                    if (showSongs) ...[
                      _buildSectionTitle('为你推荐'),
                      SizedBox(height: AppTheme.spaceSm),
                      _buildSongsList(),
                    ],
                    SizedBox(height: 100),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===== Banner 轮播 =====
  Widget _buildBannerCarousel() {
    return SizedBox(
      height: 172,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _controller.banners.length,
        itemBuilder: (context, index) {
          final banner = _controller.banners[index];
          return Container(
            width: MediaQuery.of(context).size.width - 40,
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              gradient: AppTheme.primaryToSecondary,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (banner['image'] != null)
                    CachedNetworkImage(
                      imageUrl: banner['image'],
                      fit: BoxFit.cover,
                      memCacheWidth: 800, // 优化内存占用，限制缓存图片宽度
                      placeholder: (_, __) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.brandIndigo.withOpacity(0.3),
                              AppTheme.brandPurple.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          banner['title'] ?? '',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          banner['subtitle'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== Section Title：textSilver 色，字号 16，不加粗，右侧"查看更多" 小号 + 箭头 =====
  Widget _buildSectionTitle(String title, {VoidCallback? onMore}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: AppTheme.textSilver,
              letterSpacing: 0.2,
            ),
          ),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '查看更多',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightGray,
                    ),
                  ),
                  SizedBox(width: 1),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: AppTheme.textLightGray,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===== Quick Actions：3个surface3卡片 =====
  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.auto_awesome_rounded,
              title: '每日推荐',
              subtitle: '精挑细选',
              gradientColors: [AppTheme.brandIndigo, AppTheme.brandPurple],
              onTap: () => Get.toNamed(AppRoutes.fm),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.bar_chart_rounded,
              title: '排行榜',
              subtitle: '流行风向',
              gradientColors: [AppTheme.brandCyan, AppTheme.brandIndigo],
              onTap: _showHotChartsSheet,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.auto_awesome_rounded,
              title: '创作',
              subtitle: '用AI写歌',
              gradientColors: [AppTheme.brandPurple, AppTheme.brandPink],
              onTap: () => Get.to(() => CreatePage()),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Quick Action Card：surface3 基底 =====
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return ElasticButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: AppTheme.brandIndigo.withOpacity(0.15),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (gradientColors.first).withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: gradientColors.first.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: gradientColors.first),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSilver,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Daily Recommend =====
  Widget _buildDailyRecommendSection() {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _controller.dailyRecommend.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildDailyRecommendCard(
              _controller.dailyRecommend[index]);
        },
      ),
    );
  }

  Widget _buildDailyRecommendCard(Map song) {
    return ElasticButton(
      onTap: () =>
          Get.toNamed(AppRoutes.musicDetail, arguments: song['id']),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (song['cover_url'] != null &&
                        song['cover_url'].toString().isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: song['cover_url'],
                        fit: BoxFit.cover,
                        memCacheWidth: 320, // 优化内存占用，卡片宽度约160px，2倍分辨率
                        placeholder: (_, __) => _buildGradientPlaceholder(),
                        errorWidget: (_, __, ___) =>
                            _buildGradientPlaceholder(),
                      )
                    else
                      _buildGradientPlaceholder(),
                    // Bottom gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Play button
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              song['title'] ?? '',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textWhite,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              song['artist_name'] ?? '未知歌手',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSilver,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brandIndigo, AppTheme.brandPurple],
        ),
      ),
      child: Center(
        child: Icon(Icons.music_note_rounded,
            size: 48, color: AppTheme.textWhite),
      ),
    );
  }

  // ===== Hot Charts（surface2 cards） =====
  Widget _buildHotChartSection() {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _controller.hotCharts.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildHotChartItem(_controller.hotCharts[index]);
        },
      ),
    );
  }

  Widget _buildHotChartItem(Map chart) {
    return ElasticButton(
      onTap: () => Get.toNamed(AppRoutes.musicDetail, arguments: chart['id']),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: AppTheme.brandIndigo.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.brandIndigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getChartIcon(chart['type']),
                  size: 20,
                  color: AppTheme.brandIndigo,
                ),
              ),
              SizedBox(height: 8),
              Text(
                chart['name'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textWhite,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                chart['description'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSilver,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getChartIcon(String? type) {
    switch (type) {
      case 'hot':
        return Icons.trending_up;
      case 'new':
        return Icons.new_releases;
      case 'original':
        return Icons.mic;
      default:
        return Icons.bar_chart;
    }
  }

  // ===== 心情推荐区域 =====
  /// 根据当前时间段推荐不同风格音乐
  Widget _buildMoodRecommendSection() {
    final moodData = _getCurrentMoodRecommend();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 心情标签
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: moodData['color'].withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              border: Border.all(
                color: moodData['color'].withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  moodData['emoji'],
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 6),
                Text(
                  moodData['title'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: moodData['color'],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          // 歌曲列表
          ...List.generate(
            (moodData['songs'] as List).length,
            (index) => _buildMoodSongItem(moodData['songs'][index], moodData['color']),
          ),
        ],
      ),
    );
  }

  /// 获取当前时间段的心情推荐数据
  Map<String, dynamic> _getCurrentMoodRecommend() {
    final hour = DateTime.now().hour;

    // 早安音乐 (6:00-11:00)
    if (hour >= 6 && hour < 11) {
      return {
        'emoji': '🌅',
        'title': '早安音乐',
        'color': AppTheme.moodMorning,
        'songs': [
          {'title': '阳光正好', 'artist': 'AI创作', 'mood': '元气满满的一天'},
          {'title': '晨曦微风', 'artist': 'AI创作', 'mood': '清晨的第一缕阳光'},
          {'title': '早安世界', 'artist': 'AI创作', 'mood': '新的一天开始了'},
        ],
      };
    }

    // 午后放松 (11:00-14:00)
    if (hour >= 11 && hour < 14) {
      return {
        'emoji': '☕',
        'title': '午后放松',
        'color': AppTheme.moodAfternoon,
        'songs': [
          {'title': '咖啡时光', 'artist': 'AI创作', 'mood': '惬意的午后'},
          {'title': '慵懒午后', 'artist': 'AI创作', 'mood': '享受片刻宁静'},
          {'title': '微风轻拂', 'artist': 'AI创作', 'mood': '午后的温柔'},
        ],
      };
    }

    // 下午活力 (14:00-18:00)
    if (hour >= 14 && hour < 18) {
      return {
        'emoji': '⚡',
        'title': '下午活力',
        'color': AppTheme.moodVitality,
        'songs': [
          {'title': '能量满满', 'artist': 'AI创作', 'mood': '下午也要加油'},
          {'title': '节奏律动', 'artist': 'AI创作', 'mood': '保持专注'},
          {'title': '冲刺时刻', 'artist': 'AI创作', 'mood': '最后的奋斗'},
        ],
      };
    }

    // 傍晚黄昏 (18:00-20:00)
    if (hour >= 18 && hour < 20) {
      return {
        'emoji': '🌇',
        'title': '傍晚黄昏',
        'color': AppTheme.moodDusk,
        'songs': [
          {'title': '夕阳西下', 'artist': 'AI创作', 'mood': '落日余晖'},
          {'title': '归途', 'artist': 'AI创作', 'mood': '回家的路上'},
          {'title': '黄昏独白', 'artist': 'AI创作', 'mood': '一天即将结束'},
        ],
      };
    }

    // 夜晚陪伴 (20:00-23:00)
    if (hour >= 20 && hour < 23) {
      return {
        'emoji': '🌙',
        'title': '夜晚陪伴',
        'color': AppTheme.moodNight,
        'songs': [
          {'title': '夜色温柔', 'artist': 'AI创作', 'mood': '夜晚的宁静'},
          {'title': '星光点点', 'artist': 'AI创作', 'mood': '仰望星空'},
          {'title': '月光曲', 'artist': 'AI创作', 'mood': '月色如水'},
        ],
      };
    }

    // 深夜电台 (23:00-6:00)
    return {
      'emoji': '🌃',
      'title': '深夜电台',
      'color': AppTheme.moodLateNight,
      'songs': [
        {'title': '深夜独白', 'artist': 'AI创作', 'mood': '夜深人静'},
        {'title': '枕边故事', 'artist': 'AI创作', 'mood': '陪你入眠'},
        {'title': '凌晨三点', 'artist': 'AI创作', 'mood': '深夜的思绪'},
      ],
    };
  }

  /// 心情推荐歌曲项
  Widget _buildMoodSongItem(Map song, Color accentColor) {
    return ElasticButton(
      onTap: () {
        // 跳转到搜索页，搜索对应歌曲标题
        final keyword = song['title'] ?? '';
        if (keyword.isNotEmpty) {
          Get.toNamed(AppRoutes.search, arguments: keyword);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: accentColor.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // 音乐图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.music_note_rounded,
                size: 20,
                color: accentColor,
              ),
            ),
            SizedBox(width: 12),
            // 歌曲信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['title'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    song['mood'],
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSilver,
                    ),
                  ),
                ],
              ),
            ),
            // 播放按钮
            Icon(
              Icons.play_arrow_rounded,
              size: 24,
              color: accentColor.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 猜你喜欢区域 =====
  /// 根据听歌历史推荐相似风格
  Widget _buildGuessYouLikeSection() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _guessYouLikeData.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildGuessYouLikeCard(_guessYouLikeData[index]);
        },
      ),
    );
  }

  /// 猜你喜欢推荐数据
  List<Map<String, dynamic>> get _guessYouLikeData => [
    {
      'title': '流行热歌',
      'subtitle': '根据你的收听习惯',
      'icon': Icons.trending_up_rounded,
      'color': Color(0xFFFF6B6B),
      'tag': '风格匹配',
    },
    {
      'title': '轻音乐',
      'subtitle': '放松心情的好选择',
      'icon': Icons.self_improvement_rounded,
      'color': Color(0xFF4ECDC4),
      'tag': '情绪匹配',
    },
    {
      'title': '电子音乐',
      'subtitle': '节奏感十足',
      'icon': Icons.electric_bolt_rounded,
      'color': Color(0xFFFFE66D),
      'tag': '相似推荐',
    },
    {
      'title': '民谣精选',
      'subtitle': '温暖治愈的声音',
      'icon': Icons.queue_music_rounded,
      'color': Color(0xFF95E1D3),
      'tag': '风格匹配',
    },
    {
      'title': '古风国韵',
      'subtitle': '东方美学之声',
      'icon': Icons.temple_buddhist_rounded,
      'color': Color(0xFFF38181),
      'tag': '热门推荐',
    },
  ];

  /// 猜你喜欢卡片
  Widget _buildGuessYouLikeCard(Map<String, dynamic> data) {
    return ElasticButton(
      onTap: () {
        // 跳转到搜索页，搜索对应风格关键词
        final keyword = data['title'] ?? '';
        if (keyword.isNotEmpty) {
          Get.toNamed(AppRoutes.search, arguments: keyword);
        }
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: (data['color'] as Color).withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标签
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (data['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                ),
                child: Text(
                  data['tag'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: data['color'],
                  ),
                ),
              ),
              SizedBox(height: 12),
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (data['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  data['icon'],
                  size: 22,
                  color: data['color'],
                ),
              ),
              SizedBox(height: 10),
              // 标题
              Text(
                data['title'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 2),
              // 副标题
              Text(
                data['subtitle'],
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSilver,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Creator Stars =====
  Widget _buildCreatorStarsSection() {
    return FutureBuilder<List>(
      future: _loadCreatorStars(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                width: 140,
                margin: EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    ShimmerLoading(
                        width: 80, height: 80,
                        borderRadius: 40),
                    SizedBox(height: 12),
                    ShimmerLoading(width: 80, height: 14),
                    SizedBox(height: 6),
                    ShimmerLoading(width: 100, height: 10),
                  ],
                ),
              ),
            ),
          );
        }

        final creators = snapshot.data ?? [];
        if (creators.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                '暂无创作明星',
                style: TextStyle(color: AppTheme.textSilver),
              ),
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: creators.length,
            separatorBuilder: (_, __) => SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildCreatorCard(creators[index]);
            },
          ),
        );
      },
    );
  }

  Future<List> _loadCreatorStars() async {
    try {
      final response = await HttpUtil().get('/creator/stars');
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Widget _buildCreatorCard(Map creator) {
    return Container(
      width: 140,
      child: ElasticButton(
        onTap: () => Get.toNamed(AppRoutes.publicProfile,
            arguments: creator['user_id']),
        child: Column(
          children: [
            // Avatar with subtle glow
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.brandIndigo, AppTheme.brandPurple],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandIndigo.withOpacity(0.25),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: creator['avatar'] != null
                    ? CachedNetworkImage(
                        imageUrl: creator['avatar'],
                        fit: BoxFit.cover,
                        memCacheWidth: 160, // 优化内存占用，头像80px，2倍分辨率
                        errorWidget: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: AppTheme.textWhite),
                      )
                    : Icon(Icons.person_rounded,
                        size: 40, color: AppTheme.textWhite),
              ),
            ),
            SizedBox(height: 8),
            Text(
              creator['nickname'] ?? '创作者',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textWhite,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              '${creator['works_count'] ?? 0} 作品',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSilver,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Playlists =====
  Widget _buildPlaylistsSection() {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _controller.playlists.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildPlaylistCard(_controller.playlists[index]);
        },
      ),
    );
  }

  Widget _buildPlaylistCard(Map playlist) {
    final hasCover = playlist['cover'] != null &&
        playlist['cover'].toString().isNotEmpty;
    return ElasticButton(
      onTap: () =>
          Get.toNamed(AppRoutes.playlist, arguments: playlist['id']),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasCover)
                      CachedNetworkImage(
                        imageUrl: playlist['cover'],
                        fit: BoxFit.cover,
                        memCacheWidth: 300, // 优化内存占用，卡片宽度约150px，2倍分辨率
                        placeholder: (_, __) => Container(
                            color: AppTheme.surface2),
                        errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surface2,
                            child: Icon(
                                Icons.music_note_rounded,
                                size: 40,
                                color: AppTheme.textWhite)),
                      )
                    else
                      Container(
                        color: AppTheme.surface2,
                        child: Icon(Icons.music_note_rounded,
                            size: 40, color: AppTheme.textWhite),
                      ),
                    // Bottom gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Play button
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 14,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6),
            Text(
              playlist['name'] ?? '',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textWhite,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              '${playlist['song_count'] ?? 0} 首',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSilver,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Recommended Songs（分页无限滚动） =====
  Widget _buildSongsList() {
    final songs = _controller.songs;
    // 使用 NotificationListener 检测滚动到底部
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 仅响应列表项的滚动事件，且已滚动到底部附近
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100) {
          _controller.loadMoreSongs();
        }
        return false;
      },
      child: Column(
        children: [
          // 歌曲列表使用 Column + List.generate 保持原有布局
          ...List.generate(songs.length, (index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildSongItem(songs[index] as Map, index),
            );
          }),
          // 底部加载状态指示器
          _buildLoadMoreIndicator(),
        ],
      ),
    );
  }

  /// 底部加载更多指示器
  Widget _buildLoadMoreIndicator() {
    return Obx(() {
      if (_controller.isLoadingMore.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
        );
      }
      if (!_controller.hasMore.value && _controller.songs.isNotEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            '—— 到底了 ——',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textLightGray,
            ),
          ),
        );
      }
      return SizedBox.shrink();
    });
  }

  Widget _buildSongItem(Map song, int index) {
    final hasCover = song['cover_url'] != null &&
        song['cover_url'].toString().isNotEmpty;
    return FadeInWidget(
      delayMs: index * 60,
      child: Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface3,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(
          color: AppTheme.borderSubtle.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: ElasticButton(
        onTap: () =>
            Get.toNamed(AppRoutes.musicDetail, arguments: song['id']),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Cover - Hero 共享元素过渡
              Hero(
                tag: 'song_cover_${song['id']}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasCover
                      ? CachedNetworkImage(
                          imageUrl: song['cover_url'],
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          memCacheWidth: 108, // 优化内存占用，54px * 2倍分辨率
                          placeholder: (_, __) =>
                              Container(width: 54, height: 54, color: AppTheme.surface2),
                          errorWidget: (_, __, ___) =>
                              Container(width: 54, height: 54, color: AppTheme.surface2),
                        )
                      : Container(
                          width: 54,
                          height: 54,
                          color: AppTheme.surface2,
                          child: Icon(Icons.music_note_rounded,
                              size: 28, color: Colors.white54),
                        ),
                ),
              ),
              SizedBox(width: 12),
              // Title & artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song['title'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      song['artist_name'] ?? '未知歌手',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSilver,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Play count
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded,
                      size: 14, color: AppTheme.textLightGray),
                  SizedBox(width: 2),
                  Text(
                    _formatPlayCount(song['play_count'] ?? 0),
                    style: TextStyle(
                      fontSize: 11, color: AppTheme.textLightGray),
                  ),
                ],
              ),
              SizedBox(width: 6),
              // Like
              LikeButton(
                isLiked: false,
                size: 18,
                onTap: () => _likeSong(song),
              ),
              SizedBox(width: 2),
              // More
              InkWell(
                onTap: () => _showSongMoreMenu(song),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.more_vert_rounded,
                      size: 16, color: AppTheme.textLightGray),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// 显示排行榜底部面板
  void _showHotChartsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示条
            Container(
              margin: EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '热门榜单',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
            Container(
              height: 0.5,
              color: AppTheme.borderSubtle.withOpacity(0.3),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: _controller.hotCharts.length,
                itemBuilder: (_, index) {
                  final chart = _controller.hotCharts[index];
                  return InkWell(
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.musicDetail,
                          arguments: chart['id']);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.brandIndigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getChartIcon(chart['type']),
                              size: 20,
                              color: AppTheme.brandIndigo,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chart['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textWhite,
                                  ),
                                ),
                                if (chart['description'] != null &&
                                    chart['description']
                                        .toString()
                                        .isNotEmpty) ...[
                                  SizedBox(height: 2),
                                  Text(
                                    chart['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSilver,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 20, color: AppTheme.textLightGray),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 收藏歌曲
  void _likeSong(Map song) async {
    final songId = song['id'];
    if (songId == null) return;
    try {
      final response = await HttpUtil().post('/music/$songId/like');
      if (response.data['code'] == 0) {
        Get.snackbar('提示', '已收藏',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.primaryColor,
            colorText: AppTheme.textWhite);
      } else {
        Get.snackbar('提示', response.data['msg'] ?? '收藏失败',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.primaryColor,
            colorText: AppTheme.textWhite);
      }
    } catch (e) {
      Get.snackbar('提示', '网络错误',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primaryColor,
          colorText: AppTheme.textWhite);
    }
  }

  /// 显示歌曲更多操作菜单
  void _showSongMoreMenu(Map song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示条
            Container(
              margin: EdgeInsets.only(top: 10, bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildMenuOption(
              icon: Icons.playlist_add_rounded,
              label: '添加到歌单',
              onTap: () {
                Get.back();
                _showAddToPlaylistSheet(song);
              },
            ),
            _buildMenuOption(
              icon: Icons.share_outlined,
              label: '分享',
              onTap: () {
                Get.back();
                ShareUtil.shareSong(Map<String, dynamic>.from(song));
              },
            ),
            _buildMenuOption(
              icon: Icons.favorite_border_rounded,
              label: '收藏',
              onTap: () {
                Get.back();
                _likeSong(song);
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 显示添加到歌单底部面板
  void _showAddToPlaylistSheet(Map song) async {
    try {
      final response = await HttpUtil().get('/playlist/list');
      final playlists = response.data['data'] ?? [];
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLightGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '添加到歌单',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
              Container(
                height: 0.5,
                color: AppTheme.borderSubtle.withOpacity(0.3),
              ),
              if (playlists.isEmpty)
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      '暂无歌单，快去创建一个吧~',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLightGray,
                      ),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: playlists.length,
                    itemBuilder: (_, index) {
                      final playlist = playlists[index];
                      final name = playlist['name'] ?? '未命名歌单';
                      final songCount = playlist['song_count'] ?? 0;
                      final cover =
                          playlist['cover'] ?? playlist['cover_url'] ?? '';
                      return InkWell(
                        onTap: () => _addToPlaylist(playlist['id'], song['id']),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: cover.toString().isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: cover,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            _buildPlaylistPlaceholder(),
                                      )
                                    : _buildPlaylistPlaceholder(),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textWhite,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '$songCount 首',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSilver,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      Get.snackbar('提示', '加载歌单失败',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primaryColor,
          colorText: AppTheme.textWhite);
    }
  }

  /// 添加歌曲到歌单
  void _addToPlaylist(dynamic playlistId, dynamic songId) async {
    try {
      final response =
          await HttpUtil().post('/playlist/$playlistId/add', data: {
        'song_id': songId,
      });
      Get.back();
      if (response.data['code'] == 0) {
        Get.snackbar('提示', '已添加到歌单',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.primaryColor,
            colorText: AppTheme.textWhite);
      } else {
        Get.snackbar('提示', response.data['msg'] ?? '添加失败',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.primaryColor,
            colorText: AppTheme.textWhite);
      }
    } catch (e) {
      Get.back();
      Get.snackbar('提示', '网络错误',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primaryColor,
          colorText: AppTheme.textWhite);
    }
  }

  /// 构建菜单选项
  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textWhite, size: 22),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建歌单占位图
  Widget _buildPlaylistPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.music_note_rounded,
          size: 22, color: AppTheme.textSilver),
    );
  }

  String _formatPlayCount(dynamic count) {
    if (count is int) {
      if (count >= 10000) {
        return '${(count / 10000).toStringAsFixed(1)}万';
      }
      return count.toString();
    }
    return '0';
  }
}

/// ===== Shimmer Loading =====
class RecommendTabShimmer extends StatelessWidget {
  RecommendTabShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        // Quick actions
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _shimmerGlassBlock(),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _shimmerGlassBlock(),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _shimmerGlassBlock(),
              ),
            ],
          ),
        ),
        SizedBox(height: 28),
        // Section title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerLoading(width: 100, height: 16),
        ),
        SizedBox(height: 12),
        // Daily cards
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            itemBuilder: (_, __) => Container(
              width: 160,
              margin: EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(width: double.infinity, height: 150, borderRadius: 16),
                  SizedBox(height: 8),
                  ShimmerLoading(width: 120, height: 14),
                  SizedBox(height: 4),
                  ShimmerLoading(width: 70, height: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmerGlassBlock() {
    return ShimmerLoading(
      width: double.infinity,
      height: 94,
      borderRadius: 16,
    );
  }
}
