import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/membership/membership_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 会员中心页面
class MembershipPage extends GetView<MembershipController> {
  MembershipPage({super.key});

  // 金色 — SVIP标识
  static Color _gold = Color(0xFFFFD700);
  static Color _goldDark = Color(0xFFB8860B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Text(
          '会员中心',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppTheme.textWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.brandIndigo,
        backgroundColor: AppTheme.surface2,
        onRefresh: () => controller.loadAllData(),
        child: Obx(() {
          if (controller.isLoading.value && controller.membershipInfo.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.brandIndigo),
            );
          }
          return SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                _buildStatusCard(),
                SizedBox(height: 24),
                _buildDiscountSection(),
                SizedBox(height: 24),
                _buildSectionTitle('VIP 套餐'),
                SizedBox(height: 12),
                _buildVIPPlans(),
                SizedBox(height: 24),
                _buildSectionTitle('音币充值'),
                SizedBox(height: 12),
                _buildCoinPackages(),
                SizedBox(height: 24),
                _buildCheckInSection(),
                SizedBox(height: 24),
                _buildPrivilegeTable(),
                SizedBox(height: 40),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ===================== 顶部会员状态卡片 =====================
  Widget _buildStatusCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() {
        final level = controller.membershipInfo['level'] ?? 0;
        final isSVIP = level == 2;
        final isVIP = level >= 1;
        final accentColor = isSVIP ? _gold : AppTheme.brandIndigo;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSVIP
                  ? [_gold.withValues(alpha: 0.15), _goldDark.withValues(alpha: 0.08)]
                  : [
                      AppTheme.brandIndigo.withValues(alpha: 0.12),
                      AppTheme.brandPurple.withValues(alpha: 0.06),
                    ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // 等级图标
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.15),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Icon(
                      isSVIP ? Icons.diamond_rounded : (isVIP ? Icons.star_rounded : Icons.person_rounded),
                      size: 28,
                      color: accentColor,
                    ),
                  ),
                  SizedBox(width: 16),
                  // 等级信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.levelName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          isVIP ? '到期时间: ${controller.expireTime}' : '开通会员享更多特权',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSilver,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 音币余额
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on_rounded, size: 18, color: accentColor),
                          SizedBox(width: 4),
                          Text(
                            '${controller.coinBalance}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        '音币余额',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSilver),
                      ),
                    ],
                  ),
                ],
              ),
              // AI配额信息
              SizedBox(height: 16),
              _buildQuotaInfo(accentColor),
            ],
          ),
        );
      }),
    );
  }

  // ===================== AI配额信息 =====================
  Widget _buildQuotaInfo(Color accentColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(
          color: AppTheme.borderSubtle.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // AI创作次数
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: accentColor.withValues(alpha: 0.8),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日AI创作',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textDim,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      controller.aiQuotaText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 分隔线
          Container(
            width: 1,
            height: 32,
            color: AppTheme.borderSubtle.withValues(alpha: 0.3),
          ),
          // 配额说明
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '会员配额',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textDim,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _getQuotaDescription(),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSilver,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 获取配额说明
  String _getQuotaDescription() {
    final level = controller.membershipInfo['level'] ?? 0;
    switch (level) {
      case 1:
        return 'VIP: 20次/天';
      case 2:
        return 'SVIP: 无限次';
      default:
        return '普通: 3次/天';
    }
  }

  // ===================== 限时折扣区域 =====================
  Widget _buildDiscountSection() {
    // 模拟折扣数据（实际从接口获取）
    final discounts = [
      {'name': 'VIP月卡限时特惠', 'level': 1, 'duration': 30, 'originalPrice': 2500, 'discountPrice': 1800, 'endAt': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 86400 * 2},
      {'name': 'SVIP季卡限时特惠', 'level': 2, 'duration': 90, 'originalPrice': 7500, 'discountPrice': 4800, 'endAt': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 86400 * 5},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 18, color: AppTheme.errorColor),
              SizedBox(width: 6),
              Text(
                '限时折扣',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                ),
                child: Text(
                  'HOT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...discounts.map((d) => _buildDiscountCard(d)),
        ],
      ),
    );
  }

  /// 单个折扣卡片
  Widget _buildDiscountCard(Map<String, dynamic> discount) {
    final level = discount['level'] as int;
    final isSVIP = level == 2;
    final accentColor = isSVIP ? _gold : AppTheme.brandIndigo;
    final originalPrice = (discount['originalPrice'] as int) / 100;
    final discountPrice = (discount['discountPrice'] as int) / 100;
    final endAt = discount['endAt'] as int;
    final duration = discount['duration'] as int;
    final durationText = duration >= 365
        ? '${(duration / 365).round()}年'
        : duration >= 30
            ? '${(duration / 30).round()}个月'
            : '$duration天';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSVIP
              ? [_gold.withValues(alpha: 0.1), _goldDark.withValues(alpha: 0.05)]
              : [AppTheme.brandIndigo.withValues(alpha: 0.1), AppTheme.brandPurple.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // 左侧信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 活动名称
                Text(
                  discount['name'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                SizedBox(height: 6),
                // 时长标签
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  ),
                  child: Text(
                    isSVIP ? 'SVIP $durationText' : 'VIP $durationText',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: accentColor,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // 价格：原价划线 + 折扣价
                Row(
                  children: [
                    Text(
                      '¥${originalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textDarkGray,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppTheme.textDarkGray,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '¥${discountPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 右侧：倒计时 + 按钮
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 倒计时
              _CountdownTimer(endAt: endAt),
              SizedBox(height: 10),
              // 立即抢购按钮
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _showDiscountConfirm(discount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: isSVIP ? Colors.black : AppTheme.surface1,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '立即抢购',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 折扣购买确认弹窗
  void _showDiscountConfirm(Map<String, dynamic> discount) {
    final level = discount['level'] as int;
    final isSVIP = level == 2;
    final discountPrice = (discount['discountPrice'] as int) / 100;
    final duration = discount['duration'] as int;
    final durationText = duration >= 30 ? '${(duration / 30).round()}个月' : '$duration天';

    Get.defaultDialog(
      title: '确认购买',
      titleStyle: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600),
      middleText: '确定以 ¥${discountPrice.toStringAsFixed(0)} 购买 ${isSVIP ? "SVIP" : "VIP"} $durationText？',
      middleTextStyle: TextStyle(color: AppTheme.textSilver),
      backgroundColor: AppTheme.surface3,
      radius: AppTheme.radiusLarge,
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          Get.snackbar(
            '购买成功',
            '已成功开通 ${isSVIP ? "SVIP" : "VIP"} $durationText',
            backgroundColor: AppTheme.successColor.withValues(alpha: 0.9),
            colorText: AppTheme.textWhite,
            snackPosition: SnackPosition.TOP,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSVIP ? _gold : AppTheme.brandIndigo,
          foregroundColor: isSVIP ? Colors.black : AppTheme.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
        ),
        child: Text('确认'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text('取消', style: TextStyle(color: AppTheme.textSilver)),
      ),
    );
  }

  // ===================== 区域标题 =====================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppTheme.textWhite,
        ),
      ),
    );
  }

  // ===================== VIP 套餐选择 =====================
  Widget _buildVIPPlans() {
    return Obx(() {
      final plans = controller.vipPlans;
      if (plans.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface3.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            ),
            child: Center(
              child: Text('暂无可用套餐', style: TextStyle(color: AppTheme.textSilver)),
            ),
          ),
        );
      }

      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: plans.length,
          separatorBuilder: (_, __) => SizedBox(width: 10),
          itemBuilder: (context, i) {
            final plan = plans[i];
            final isSelected = controller.selectedVIPPlan.value == i;
            final isPopular = plan['is_popular'] == true;
            final tag = isPopular ? '热门' : '';
            final priceYuan = ((plan['price'] ?? 0) as num).toDouble() / 100;
            final durationDays = (plan['duration'] ?? 0) as int;
            final durationText = durationDays >= 365
                ? '${(durationDays / 365).round()}年'
                : durationDays >= 30
                    ? '${(durationDays / 30).round()}个月'
                    : '$durationDays天';

            return GestureDetector(
              onTap: () => controller.selectedVIPPlan.value = i,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 120,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.brandIndigo.withValues(alpha: 0.12)
                      : AppTheme.surface3.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.brandIndigo.withValues(alpha: 0.6)
                        : isPopular
                            ? AppTheme.brandIndigo.withValues(alpha: 0.3)
                            : AppTheme.borderSubtle.withValues(alpha: 0.4),
                    width: isPopular || isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (tag.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.brandIndigo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        child: Text(tag, style: TextStyle(
                          fontSize: 10, color: AppTheme.brandIndigo, fontWeight: FontWeight.w600,
                        )),
                      ),
                    Text(plan['name'] ?? '', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.textWhite : AppTheme.textSilver,
                    )),
                    SizedBox(height: 4),
                    Text('¥${priceYuan.toStringAsFixed(0)}', style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.textWhite : AppTheme.textSilver,
                    )),
                    SizedBox(height: 2),
                    Text(durationText, style: TextStyle(
                      fontSize: 11, color: AppTheme.textDarkGray,
                    )),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ===================== 音币充值包（2行3列网格） =====================
  Widget _buildCoinPackages() {
    return Obx(() {
      final packages = controller.coinPackages;
      if (packages.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface3.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            ),
            child: Center(
              child: Text('暂无可用充值包', style: TextStyle(color: AppTheme.textSilver)),
            ),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final pkg = packages[index];
            final bonus = pkg['bonus'] ?? 0;
            final priceYuan = ((pkg['price'] ?? 0) as num).toDouble() / 100;

            return GestureDetector(
              onTap: () => _showBuyCoinConfirm(pkg),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface3.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                  border: Border.all(
                    color: AppTheme.borderSubtle.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 26,
                      color: AppTheme.brandIndigo,
                    ),
                    SizedBox(height: 6),
                    Text(
                      '${pkg['coins']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    if (bonus > 0)
                      Text(
                        '赠$bonus',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    SizedBox(height: 4),
                    Text(
                      '¥${priceYuan.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSilver,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ===================== 签到综合面板 =====================
  Widget _buildCheckInSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行：签到 + 连续签到天数
          _buildCheckInHeader(),
          SizedBox(height: 16),
          // 签到日历（近7天）
          _buildCheckInCalendar(),
          SizedBox(height: 16),
          // 连续签到奖励预览
          _buildStreakRewardBar(),
          SizedBox(height: 16),
          // 签到按钮 + 动画
          _buildCheckInButtonWithAnimation(),
        ],
      ),
    );
  }

  /// 签到面板标题 + 连续签到天数
  Widget _buildCheckInHeader() {
    return Obx(() {
      final streak = controller.streakDays.value;
      return Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.brandIndigo),
          SizedBox(width: 8),
          Text(
            '每日签到',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          Spacer(),
          // 连续签到天数
          if (streak > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded, size: 14, color: AppTheme.warningColor),
                  SizedBox(width: 4),
                  Text(
                    '连续$streak天',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  /// 签到日历 — 展示近7天签到状态
  Widget _buildCheckInCalendar() {
    return Obx(() {
      final now = DateTime.now();
      // 获取本周一
      final weekday = now.weekday;
      final monday = now.subtract(Duration(days: weekday - 1));
      final dayNames = ['一', '二', '三', '四', '五', '六', '日'];

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface3.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: AppTheme.borderSubtle.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: List.generate(7, (index) {
            final date = monday.add(Duration(days: index));
            final dateStr = date.toString().substring(0, 10);
            final isChecked = controller.checkInDates.contains(dateStr);
            final isToday = dateStr == now.toString().substring(0, 10);
            final isFuture = date.isAfter(now);

            return Expanded(
              child: Column(
                children: [
                  // 星期标签
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: isToday ? AppTheme.brandIndigo : AppTheme.textDarkGray,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8),
                  // 日期圆圈
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChecked
                          ? AppTheme.brandIndigo.withValues(alpha: 0.2)
                          : isToday
                              ? AppTheme.brandIndigo.withValues(alpha: 0.08)
                              : Colors.transparent,
                      border: isToday && !isChecked
                          ? Border.all(color: AppTheme.brandIndigo.withValues(alpha: 0.5), width: 1)
                          : null,
                    ),
                    child: Center(
                      child: isChecked
                          ? Icon(Icons.check_rounded, size: 16, color: AppTheme.brandIndigo)
                          : Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                                color: isFuture
                                    ? AppTheme.textDarkGray
                                    : isToday
                                        ? AppTheme.brandIndigo
                                        : AppTheme.textSilver,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    });
  }

  /// 连续签到奖励进度条
  Widget _buildStreakRewardBar() {
    return Obx(() {
      final streak = controller.streakDays.value;
      // 奖励规则：第1天10，第2天15，第3天20...第7天50
      final rewards = [10, 15, 20, 25, 30, 40, 50];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '连续签到奖励',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSilver,
                ),
              ),
              Text(
                '明日可领 ${rewards[streak.clamp(0, 6)]} 币',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textDarkGray,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          // 奖励进度指示器
          Row(
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              final reward = rewards[index];
              final isCompleted = streak >= dayNum;
              final isCurrent = streak == index;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      // 进度圆点
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppTheme.brandIndigo
                              : isCurrent
                                  ? AppTheme.brandIndigo.withValues(alpha: 0.15)
                                  : AppTheme.surface3,
                          border: isCurrent
                              ? Border.all(color: AppTheme.brandIndigo, width: 1.5)
                              : isCompleted
                                  ? null
                                  : Border.all(color: AppTheme.borderSubtle, width: 0.5),
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.check_rounded, size: 14, color: AppTheme.textWhite)
                              : Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrent ? AppTheme.brandIndigo : AppTheme.textDarkGray,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 4),
                      // 奖励数值
                      Text(
                        '$reward',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                          color: isCompleted ? AppTheme.brandIndigo : AppTheme.textDarkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      );
    });
  }

  /// 签到按钮 + 数字跳动动画
  Widget _buildCheckInButtonWithAnimation() {
    return Obx(() {
      final checked = controller.isCheckedIn.value;
      final showAnim = controller.showCheckInAnimation.value;

      return Column(
        children: [
          // 签到成功动画 — 音币数字跳动
          if (showAnim)
            _CheckInCoinAnimation(
              coins: controller.earnedCoins.value,
              onComplete: () => controller.hideCheckInAnimation(),
            ),
          // 签到按钮
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: checked ? null : () => controller.performCheckIn(),
              style: ElevatedButton.styleFrom(
                backgroundColor: checked
                    ? AppTheme.surface3
                    : AppTheme.brandIndigo,
                foregroundColor: checked
                    ? AppTheme.textDarkGray
                    : AppTheme.surface1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  side: checked
                      ? BorderSide(color: AppTheme.borderSubtle, width: 1)
                      : BorderSide.none,
                ),
                elevation: 0,
                disabledBackgroundColor: AppTheme.surface3,
                disabledForegroundColor: AppTheme.textDarkGray,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    checked ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    checked ? '今日已签到' : '签到领 ${controller.checkInReward} 音币',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  // ===================== VIP特权对比表格 =====================
  Widget _buildPrivilegeTable() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VIP 特权对比',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface3.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
              border: Border.all(
                color: AppTheme.borderSubtle.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                _buildTableHeader(),
                _buildTableRow('每日AI创作', '3次', '20次', '无限'),
                _buildDivider(),
                _buildTableRow('音质', '标准', '高品', '无损'),
                _buildDivider(),
                _buildTableRow('歌曲下载', '—', '✓', '✓'),
                _buildDivider(),
                _buildTableRow('声音克隆', '—', '5次/月', '无限'),
                _buildDivider(),
                _buildTableRow('专属客服', '—', '—', '✓'),
                _buildDivider(),
                _buildTableRow('签到音币', '10', '20', '50'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '特权',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSilver,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '免费',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDarkGray,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                ),
                child: Text(
                  'VIP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandIndigo,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                ),
                child: Text(
                  'SVIP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _gold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String label, String free, String vip, String svip) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppTheme.textWhite),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                free,
                style: TextStyle(fontSize: 13, color: AppTheme.textDarkGray),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                vip,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.brandIndigo,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                svip,
                style: TextStyle(
                  fontSize: 13,
                  color: _gold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 0.5,
        color: AppTheme.borderSubtle.withValues(alpha: 0.3),
      ),
    );
  }

  // ===================== 购买音币确认弹窗 =====================
  void _showBuyCoinConfirm(Map<String, dynamic> pkg) {
    Get.defaultDialog(
      title: '确认充值',
      titleStyle: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600),
      middleText: '确定花费 ¥${pkg['price']} 充值 ${pkg['coins']} 音币？',
      middleTextStyle: TextStyle(color: AppTheme.textSilver),
      backgroundColor: AppTheme.surface3,
      radius: AppTheme.radiusLarge,
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          controller.buyCoins(pkg['id']);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandIndigo,
          foregroundColor: AppTheme.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
        ),
        child: Text('确认'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text('取消', style: TextStyle(color: AppTheme.textSilver)),
      ),
    );
  }
}

/// 倒计时组件（天:时:分:秒）
class _CountdownTimer extends StatefulWidget {
  final int endAt; // 结束时间戳（秒）

  _CountdownTimer({required this.endAt});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateRemaining());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = widget.endAt - now;
    if (diff <= 0) {
      _timer.cancel();
      setState(() => _remaining = Duration.zero);
    } else {
      setState(() => _remaining = Duration(seconds: diff));
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return Text(
        '已结束',
        style: TextStyle(fontSize: 12, color: AppTheme.textDarkGray),
      );
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '距结束 ',
          style: TextStyle(fontSize: 11, color: AppTheme.textSilver),
        ),
        if (days > 0) _buildTimeBox('$days天'),
        _buildTimeBox(_pad(hours)),
        _buildTimeSep(),
        _buildTimeBox(_pad(minutes)),
        _buildTimeSep(),
        _buildTimeBox(_pad(seconds)),
      ],
    );
  }

  Widget _buildTimeBox(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.errorColor,
        ),
      ),
    );
  }

  Widget _buildTimeSep() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        ':',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorColor),
      ),
    );
  }
}

/// 签到成功 — 音币数字跳动动画
/// 从0快速跳动到目标数值，带缩放和淡入效果
class _CheckInCoinAnimation extends StatefulWidget {
  final int coins;
  final VoidCallback onComplete;

  _CheckInCoinAnimation({required this.coins, required this.onComplete});

  @override
  State<_CheckInCoinAnimation> createState() => _CheckInCoinAnimationState();
}

class _CheckInCoinAnimationState extends State<_CheckInCoinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  int _displayCoins = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    // 弹性缩放：从小到大再弹回
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // 淡入
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // 数字跳动：分步递增到目标值
    _animateCoins();

    // 动画完成后回调
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(Duration(milliseconds: 600), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  /// 分步递增数字，模拟跳动效果
  void _animateCoins() async {
    final target = widget.coins;
    final steps = 8;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() {
        _displayCoins = (target * i / steps).round();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.brandIndigo.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.brandIndigo.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 24,
                    color: AppTheme.brandIndigo,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '签到成功 +',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  // 跳动数字
                  Text(
                    '$_displayCoins',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandIndigo,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '音币',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSilver,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
