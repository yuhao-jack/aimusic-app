import 'package:flutter/material.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 听歌统计数据模型
class ListeningStats {
  /// 今日听歌时长（分钟）
  final int todayMinutes;
  
  /// 本周听歌时长（分钟）
  final int weekMinutes;
  
  /// 总听歌数量
  final int totalSongs;
  
  /// 最常听的风格（风格名称 -> 听歌次数）
  final Map<String, int> topGenres;
  
  /// 听歌时段分布（时段 -> 听歌次数）
  /// 时段：morning(6-12), afternoon(12-18), evening(18-24), night(0-6)
  final Map<String, int> timeDistribution;

  const ListeningStats({
    required this.todayMinutes,
    required this.weekMinutes,
    required this.totalSongs,
    required this.topGenres,
    required this.timeDistribution,
  });

  /// 从播放历史创建统计数据
  factory ListeningStats.fromPlayHistory(List<Map<String, dynamic>> history) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    
    int todayMinutes = 0;
    int weekMinutes = 0;
    int totalSongs = history.length;
    
    final Map<String, int> genreCount = {};
    final Map<String, int> timeCount = {
      'morning': 0,   // 6-12
      'afternoon': 0, // 12-18
      'evening': 0,   // 18-24
      'night': 0,     // 0-6
    };

    for (final song in history) {
      final playTime = DateTime.tryParse(song['play_time'] ?? '') ?? now;
      final duration = (song['duration'] as int?) ?? 180; // 默认3分钟
      final minutes = (duration / 60).ceil();
      
      // 计算今日听歌时长
      if (playTime.isAfter(todayStart)) {
        todayMinutes += minutes;
      }
      
      // 计算本周听歌时长
      if (playTime.isAfter(weekStart)) {
        weekMinutes += minutes;
      }
      
      // 统计风格
      final genres = song['genres'] as List<dynamic>? ?? [];
      for (final genre in genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
      }
      
      // 统计时段
      final hour = playTime.hour;
      if (hour >= 6 && hour < 12) {
        timeCount['morning'] = timeCount['morning']! + 1;
      } else if (hour >= 12 && hour < 18) {
        timeCount['afternoon'] = timeCount['afternoon']! + 1;
      } else if (hour >= 18 && hour < 24) {
        timeCount['evening'] = timeCount['evening']! + 1;
      } else {
        timeCount['night'] = timeCount['night']! + 1;
      }
    }

    // 获取前3个最常听的风格
    final sortedGenres = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGenres = Map.fromEntries(sortedGenres.take(3));

    return ListeningStats(
      todayMinutes: todayMinutes,
      weekMinutes: weekMinutes,
      totalSongs: totalSongs,
      topGenres: topGenres,
      timeDistribution: timeCount,
    );
  }
}

/// 听歌统计页面
class ListeningStatsPage extends StatelessWidget {
  final ListeningStats stats;

  const ListeningStatsPage({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: const Text(
          '听歌统计',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 核心统计卡片
            _buildCoreStats(),
            const SizedBox(height: 24),
            
            // 最常听风格
            _buildTopGenres(),
            const SizedBox(height: 24),
            
            // 听歌时段分布
            _buildTimeDistribution(),
            const SizedBox(height: 24),
            
            // 经验值来源说明
            _buildExperienceSources(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// 核心统计卡片
  Widget _buildCoreStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface3.withOpacity(0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(
          color: AppTheme.borderSubtle.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.headphones_rounded,
                  value: '${stats.todayMinutes}',
                  unit: '分钟',
                  label: '今日听歌',
                  color: AppTheme.brandCyan,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.borderSubtle.withOpacity(0.4),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_view_week_rounded,
                  value: '${stats.weekMinutes}',
                  unit: '分钟',
                  label: '本周听歌',
                  color: AppTheme.brandBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.brandIndigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
              border: Border.all(
                color: AppTheme.brandIndigo.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.music_note_rounded,
                  color: AppTheme.brandIndigo,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '${stats.totalSongs}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandIndigo,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '首歌曲',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSilver,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 单个统计项
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSilver,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSilver,
          ),
        ),
      ],
    );
  }

  /// 最常听风格（标签云形式）
  Widget _buildTopGenres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最常听的风格',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        if (stats.topGenres.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface3.withOpacity(0.55),
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
              border: Border.all(
                color: AppTheme.borderSubtle.withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.music_off_rounded,
                  size: 40,
                  color: AppTheme.textDarkGray,
                ),
                SizedBox(height: 12),
                Text(
                  '暂无风格数据',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSilver,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: stats.topGenres.entries.map((entry) {
              final index = stats.topGenres.keys.toList().indexOf(entry.key);
              final colors = [
                AppTheme.brandIndigo,
                AppTheme.brandPurple,
                AppTheme.brandCyan,
              ];
              final color = colors[index % colors.length];
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getGenreIcon(entry.key),
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                      ),
                      child: Text(
                        '${entry.value}次',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// 获取风格对应的图标
  IconData _getGenreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'pop':
      case '流行':
        return Icons.music_note_rounded;
      case 'rock':
      case '摇滚':
        return Icons.electric_bolt_rounded;
      case 'hiphop':
      case 'hip-hop':
      case '说唱':
        return Icons.mic_rounded;
      case 'electronic':
      case '电子':
        return Icons.surround_sound_rounded;
      case 'classical':
      case '古典':
        return Icons.piano_rounded;
      case 'jazz':
      case '爵士':
        return Icons.music_video_rounded;
      case 'r&b':
      case 'rnb':
      case '节奏蓝调':
        return Icons.favorite_rounded;
      case 'folk':
      case '民谣':
        return Icons.nature_people_rounded;
      case 'metal':
      case '金属':
        return Icons.whatshot_rounded;
      case 'country':
      case '乡村':
        return Icons.landscape_rounded;
      default:
        return Icons.album_rounded;
    }
  }

  /// 听歌时段分布（简单柱状图）
  Widget _buildTimeDistribution() {
    final timeLabels = {
      'morning': '早晨',
      'afternoon': '下午',
      'evening': '晚上',
      'night': '深夜',
    };
    
    final timeIcons = {
      'morning': Icons.wb_sunny_rounded,
      'afternoon': Icons.wb_cloudy_rounded,
      'evening': Icons.nights_stay_rounded,
      'night': Icons.dark_mode_rounded,
    };
    
    final timeColors = {
      'morning': AppTheme.brandCyan,
      'afternoon': AppTheme.brandBlue,
      'evening': AppTheme.brandPurple,
      'night': AppTheme.brandIndigo,
    };

    final maxCount = stats.timeDistribution.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '听歌时段分布',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface3.withOpacity(0.55),
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(
              color: AppTheme.borderSubtle.withOpacity(0.4),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              // 柱状图
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: stats.timeDistribution.entries.map((entry) {
                  final label = timeLabels[entry.key] ?? entry.key;
                  final icon = timeIcons[entry.key] ?? Icons.access_time_rounded;
                  final color = timeColors[entry.key] ?? AppTheme.brandIndigo;
                  final height = maxCount > 0 
                      ? (entry.value / maxCount) * 100 
                      : 0.0;
                  
                  return Column(
                    children: [
                      // 次数
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 柱子
                      Container(
                        width: 40,
                        height: height,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: color.withOpacity(0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 30,
                            height: height - 10,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(AppTheme.radiusXSmall),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 图标
                      Icon(icon, color: color, size: 20),
                      const SizedBox(height: 4),
                      // 标签
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSilver,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // 说明
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.brandIndigo.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXSmall),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '数字表示听歌次数',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSilver,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 经验值来源说明
  Widget _buildExperienceSources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '经验值获取方式',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface3.withOpacity(0.55),
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            border: Border.all(
              color: AppTheme.borderSubtle.withOpacity(0.4),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              _buildExperienceSourceItem(
                icon: Icons.headphones_rounded,
                name: '听歌',
                points: 1,
                color: AppTheme.brandCyan,
              ),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              _buildExperienceSourceItem(
                icon: Icons.calendar_today_rounded,
                name: '签到',
                points: 5,
                color: AppTheme.brandBlue,
              ),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              _buildExperienceSourceItem(
                icon: Icons.auto_awesome_rounded,
                name: '创作',
                points: 10,
                color: AppTheme.brandPurple,
              ),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              _buildExperienceSourceItem(
                icon: Icons.share_rounded,
                name: '分享',
                points: 3,
                color: AppTheme.brandPink,
              ),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              _buildExperienceSourceItem(
                icon: Icons.favorite_rounded,
                name: '点赞',
                points: 1,
                color: AppTheme.brandPink,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 单个经验值来源项
  Widget _buildExperienceSourceItem({
    required IconData icon,
    required String name,
    required int points,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textWhite,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
            ),
            child: Text(
              '+$points',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}