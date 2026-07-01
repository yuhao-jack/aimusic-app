import 'package:flutter/material.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 用户等级徽章组件
/// 根据经验值计算等级并显示相应颜色和样式
class LevelBadge extends StatelessWidget {
  /// 用户经验值
  final int experience;

  /// 徽章尺寸
  final double size;

  /// 是否显示等级文字
  final bool showLevelText;

  /// 是否显示经验值
  final bool showExperience;

  LevelBadge({
    super.key,
    required this.experience,
    this.size = 32.0,
    this.showLevelText = true,
    this.showExperience = false,
  });

  /// 计算等级
  /// 等级规则：Lv1(0-99) → Lv2(100-299) → Lv3(300-599) → ... → Lv10(5000+)
  static int calculateLevel(int experience) {
    if (experience < 100) return 1;
    if (experience < 300) return 2;
    if (experience < 600) return 3;
    if (experience < 1000) return 4;
    if (experience < 1500) return 5;
    if (experience < 2100) return 6;
    if (experience < 2800) return 7;
    if (experience < 3600) return 8;
    if (experience < 4500) return 9;
    return 10;
  }

  /// 获取等级对应的颜色
  /// Lv1-3灰色，Lv4-6蓝色，Lv7-9紫色，Lv10金色
  static Color getLevelColor(int level) {
    if (level <= 3) return AppTheme.textLightGray; // 灰色
    if (level <= 6) return AppTheme.brandBlue; // 蓝色
    if (level <= 9) return AppTheme.brandPurple; // 紫色
    return Color(0xFFFFD700); // 金色
  }

  /// 获取等级对应的渐变色
  static LinearGradient getLevelGradient(int level) {
    final color = getLevelColor(level);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.8),
        color.withOpacity(0.4),
      ],
    );
  }

  /// 获取当前等级所需经验
  static int getExperienceForLevel(int level) {
    switch (level) {
      case 1: return 0;
      case 2: return 100;
      case 3: return 300;
      case 4: return 600;
      case 5: return 1000;
      case 6: return 1500;
      case 7: return 2100;
      case 8: return 2800;
      case 9: return 3600;
      case 10: return 4500;
      default: return 0;
    }
  }

  /// 获取下一等级所需经验
  static int getExperienceForNextLevel(int level) {
    if (level >= 10) return 5000; // 满级
    return getExperienceForLevel(level + 1);
  }

  /// 获取当前等级进度（0.0 - 1.0）
  static double getLevelProgress(int experience) {
    final level = calculateLevel(experience);
    if (level >= 10) return 1.0;
    
    final currentLevelExp = getExperienceForLevel(level);
    final nextLevelExp = getExperienceForNextLevel(level);
    final progress = (experience - currentLevelExp) / (nextLevelExp - currentLevelExp);
    
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final level = calculateLevel(experience);
    final color = getLevelColor(level);
    final progress = getLevelProgress(experience);
    final nextLevelExp = getExperienceForNextLevel(level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 等级徽章圆形
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: getLevelGradient(level),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$level',
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        // 等级文字
        if (showLevelText) ...[
          SizedBox(height: 4),
          Text(
            'Lv.$level',
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
        
        // 经验值进度条
        if (showExperience) ...[
          SizedBox(height: 8),
          SizedBox(
            width: size * 2,
            child: Column(
              children: [
                // 进度条
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.surface3,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
                SizedBox(height: 4),
                // 经验值文字
                Text(
                  '$experience / $nextLevelExp',
                  style: TextStyle(
                    fontSize: size * 0.25,
                    color: AppTheme.textSilver,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 紧凑型等级徽章（仅显示等级数字和颜色）
class CompactLevelBadge extends StatelessWidget {
  final int experience;
  final double size;

  CompactLevelBadge({
    super.key,
    required this.experience,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final level = LevelBadge.calculateLevel(experience);
    final color = LevelBadge.getLevelColor(level);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// 等级进度卡片（显示详细等级信息）
class LevelProgressCard extends StatelessWidget {
  final int experience;
  final VoidCallback? onTap;

  LevelProgressCard({
    super.key,
    required this.experience,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final level = LevelBadge.calculateLevel(experience);
    final color = LevelBadge.getLevelColor(level);
    final progress = LevelBadge.getLevelProgress(experience);
    final nextLevelExp = LevelBadge.getExperienceForNextLevel(level);
    final isMaxLevel = level >= 10;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface3.withOpacity(0.55),
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // 等级徽章
            LevelBadge(
              experience: experience,
              size: 48,
              showLevelText: false,
            ),
            SizedBox(width: 16),
            
            // 等级信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Lv.$level',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      SizedBox(width: 8),
                      if (isMaxLevel)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                          ),
                          child: Text(
                            '满级',
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  // 进度条
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.surface3,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // 经验值信息
                  Text(
                    isMaxLevel 
                        ? '已达最高等级'
                        : '距离下一级还需 ${nextLevelExp - experience} 经验',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSilver,
                    ),
                  ),
                ],
              ),
            ),
            
            // 经验值总数
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$experience',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '经验值',
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
    );
  }
}

/// 经验值来源说明
class ExperienceSource {
  final String name;
  final IconData icon;
  final int points;
  final Color color;

  ExperienceSource({
    required this.name,
    required this.icon,
    required this.points,
    required this.color,
  });

  /// 所有经验值来源
  static List<ExperienceSource> sources = [
    ExperienceSource(
      name: '听歌',
      icon: Icons.headphones_rounded,
      points: 1,
      color: AppTheme.brandCyan,
    ),
    ExperienceSource(
      name: '签到',
      icon: Icons.calendar_today_rounded,
      points: 5,
      color: AppTheme.brandBlue,
    ),
    ExperienceSource(
      name: '创作',
      icon: Icons.auto_awesome_rounded,
      points: 10,
      color: AppTheme.brandPurple,
    ),
    ExperienceSource(
      name: '分享',
      icon: Icons.share_rounded,
      points: 3,
      color: AppTheme.brandPink,
    ),
    ExperienceSource(
      name: '点赞',
      icon: Icons.favorite_rounded,
      points: 1,
      color: AppTheme.brandPink,
    ),
  ];
}