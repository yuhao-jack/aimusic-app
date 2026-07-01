import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/modules/report/listening_report_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/utils/api_config.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

/// 听歌周报页面
/// 展示本周听歌时长、数量、最常听歌曲、风格标签
class ListeningReportPage extends GetView<ListeningReportController> {
  ListeningReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Text(
          '听歌周报',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textWhite),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingShimmer();
        }
        return _buildReportContent();
      }),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          ShimmerLoading(width: double.infinity, height: 120, borderRadius: 16),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShimmerLoading(width: double.infinity, height: 80, borderRadius: 12)),
              SizedBox(width: 12),
              Expanded(child: ShimmerLoading(width: double.infinity, height: 80, borderRadius: 12)),
            ],
          ),
          SizedBox(height: 24),
          ShimmerLoading(width: double.infinity, height: 200, borderRadius: 16),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return RefreshIndicator(
      color: AppTheme.brandIndigo,
      backgroundColor: AppTheme.surface2,
      onRefresh: () => controller.loadReport(),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部概览卡片
            FadeInWidget(
              child: _buildOverviewCard(),
            ),
            SizedBox(height: 16),
            // 统计行
            FadeInWidget(
              delayMs: 100,
              child: _buildStatsRow(),
            ),
            SizedBox(height: 24),
            // 最常听的歌曲
            FadeInWidget(
              delayMs: 200,
              child: _buildTopSongsSection(),
            ),
            SizedBox(height: 24),
            // 最常听的风格
            FadeInWidget(
              delayMs: 300,
              child: _buildGenreSection(),
            ),
            SizedBox(height: 32),
            // 分享按钮
            FadeInWidget(
              delayMs: 400,
              child: _buildShareButton(),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 顶部概览卡片
  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.brandIndigo.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.brandIndigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                ),
                child: Text(
                  '本周报告',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brandIndigo,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            '听歌时长',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSilver,
            ),
          ),
          SizedBox(height: 6),
          Text(
            controller.formattedDuration,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 统计行（听歌数量 + 风格标签）
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
              border: Border.all(
                color: AppTheme.borderSubtle.withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.headphones_rounded,
                    size: 20, color: AppTheme.brandCyan),
                SizedBox(height: 10),
                Text(
                  '${controller.songCount}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '首歌曲',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSilver,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
              border: Border.all(
                color: AppTheme.borderSubtle.withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 20, color: AppTheme.brandPink),
                SizedBox(height: 10),
                Text(
                  controller.topGenre.value.isEmpty
                      ? '--'
                      : controller.topGenre.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '最爱风格',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSilver,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 最常听的3首歌
  Widget _buildTopSongsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最常听的歌曲',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
        ),
        SizedBox(height: 14),
        if (controller.topSongs.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            ),
            child: Column(
              children: [
                Icon(Icons.music_off_rounded,
                    size: 36, color: AppTheme.textDarkGray.withOpacity(0.4)),
                SizedBox(height: 10),
                Text(
                  '本周还没有听歌记录',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSilver,
                  ),
                ),
              ],
            ),
          )
        else
          ...controller.topSongs.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return _buildTopSongItem(song, index + 1);
          }),
      ],
    );
  }

  Widget _buildTopSongItem(Map<String, dynamic> song, int rank) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface3,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(
          color: AppTheme.borderSubtle.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // 排名
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppTheme.brandIndigo.withOpacity(0.15)
                  : AppTheme.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: rank <= 3
                    ? AppTheme.brandIndigo
                    : AppTheme.textSilver,
              ),
            ),
          ),
          SizedBox(width: 12),
          // 封面
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: song['cover_url'] ?? '',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppTheme.surface2,
                child: Icon(Icons.music_note, size: 18, color: AppTheme.textDarkGray),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.surface2,
                child: Icon(Icons.music_note, size: 18, color: AppTheme.textDarkGray),
              ),
            ),
          ),
          SizedBox(width: 12),
          // 歌曲信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song['title'] ?? '未知歌曲',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  song['artist'] ?? '未知歌手',
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
          // 播放次数
          Text(
            '${song['play_count']}次',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLightGray,
            ),
          ),
        ],
      ),
    );
  }

  /// 最常听风格标签
  Widget _buildGenreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '音乐风格',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
        ),
        SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(
              color: AppTheme.borderSubtle.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryToSecondary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                ),
                child: Text(
                  controller.topGenre.value.isEmpty
                      ? '暂无数据'
                      : controller.topGenre.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                '你最常听的音乐风格',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSilver,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 分享按钮
  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // 复制周报分享链接到剪贴板
          Clipboard.setData(ClipboardData(text: '${ApiConfig.shareBaseUrl}/report'));
          ToastUtil.showSuccess('链接已复制');
        },
        icon: Icon(Icons.share_rounded, size: 18),
        label: Text('分享我的周报'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandIndigo,
          foregroundColor: AppTheme.textWhite,
          padding: EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
        ),
      ),
    );
  }
}
