import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'challenge_controller.dart';

class ChallengePage extends GetView<ChallengeController> {
  ChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Text(
          '话题挑战',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
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
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 热门挑战Banner
              FadeInWidget(
                child: _buildHotChallengeBanner(),
              ),
              SizedBox(height: 24),

              // 进行中的挑战
              FadeInWidget(
                delayMs: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '进行中的挑战',
                      style: TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    Obx(() => controller.challengeList.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: _buildChallengeList(),
                          )),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ===== 热门挑战 Banner =====
  Widget _buildHotChallengeBanner() {
    return Obx(() {
      if (controller.hotChallenge.isEmpty) {
        return SizedBox.shrink();
      }
      final challenge = controller.hotChallenge;
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Text(
                  'HOT',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                challenge['title'] ?? '#春日恋歌创作挑战',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                challenge['description'] ?? '创作一首关于春天的浪漫歌曲，赢取万元奖金！',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppTheme.textWhite,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '剩余 ${challenge['days_left'] ?? 3} 天',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 24),
                  Icon(
                    Icons.people_outline,
                    color: AppTheme.textWhite,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '${challenge['participants'] ?? 1234} 人参与',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElasticButton(
                onTap: () {
                  Get.toNamed(AppRoutes.createSong);
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.textWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    ),
                    child: Text(
                      '立即参与',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ===== 空状态 =====
  Widget _buildEmptyState() {
    return FadeInWidget(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 80,
              color: AppTheme.textDarkGray,
            ),
            SizedBox(height: 16),
            Text(
              '暂无挑战',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textLightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 挑战列表 =====
  List<Widget> _buildChallengeList() {
    return controller.challengeList.asMap().entries.map((entry) {
      final index = entry.key;
      final challenge = entry.value;
      final color = _getColorByTag(challenge['tag'] ?? '');
      return FadeInWidget(
        delayMs: index * 60,
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface3,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: InkWell(
              onTap: () {
                Get.toNamed(AppRoutes.createSong);
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: 32,
                        color: color,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge['title'] ?? '#电音狂欢节',
                            style: TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                child: Text(
                                  challenge['tag'] ?? '电子',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 14,
                                    color: AppTheme.textLightGray,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${challenge['participants'] ?? 856}人',
                                    style: TextStyle(
                                      color: AppTheme.textLightGray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppTheme.textLightGray,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '剩余${challenge['days_left'] ?? 5}天',
                                    style: TextStyle(
                                      color: AppTheme.textLightGray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                      ),
                      child: Text(
                        '参与',
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ===== 根据标签获取颜色 =====
  Color _getColorByTag(String tag) {
    switch (tag) {
      case '电子':
        return Color(0xFF8B5CF6);
      case '民谣':
        return Color(0xFF10B981);
      case '国风':
        return Color(0xFFF59E0B);
      case '流行':
        return Color(0xFF3B82F6);
      case '摇滚':
        return Color(0xFFEF4444);
      default:
        return AppTheme.primaryColor;
    }
  }
}
