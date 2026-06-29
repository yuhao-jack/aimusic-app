import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/membership_service.dart';
import 'package:aimusic_app/utils/toast_util.dart';

/// 会员中心页面状态管理
class MembershipController extends GetxController {
  final MembershipService _service = Get.find<MembershipService>();

  /// 会员信息（等级、到期时间、音币余额等）
  RxMap<String, dynamic> membershipInfo = <String, dynamic>{}.obs;

  /// VIP套餐列表
  RxList<Map<String, dynamic>> vipPlans = <Map<String, dynamic>>[].obs;

  /// 音币充值包列表
  RxList<Map<String, dynamic>> coinPackages = <Map<String, dynamic>>[].obs;

  /// 当前选中的VIP套餐索引
  RxInt selectedVIPPlan = 1.obs;

  /// 是否今日已签到
  RxBool isCheckedIn = false.obs;

  /// AI创作配额信息
  RxMap<String, dynamic> aiQuota = <String, dynamic>{}.obs;

  /// 页面加载状态
  RxBool isLoading = false.obs;

  /// 连续签到天数
  final RxInt streakDays = 0.obs;

  /// 本次签到获得的音币数（用于动画展示）
  final RxInt earnedCoins = 0.obs;

  /// 是否显示签到成功动画
  final RxBool showCheckInAnimation = false.obs;

  /// 近7天签到记录（日期列表，格式 yyyy-MM-dd）
  final RxList<String> checkInDates = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  /// 加载所有数据
  Future<void> loadAllData() async {
    isLoading.value = true;
    await Future.wait([
      loadMembershipInfo(),
      loadVIPPlans(),
      loadCoinPackages(),
      loadAIQuota(),
    ]);
    isLoading.value = false;
  }

  /// 加载会员信息
  Future<void> loadMembershipInfo() async {
    final info = await _service.getMembershipInfo();
    if (info != null) {
      membershipInfo.value = info;
      isCheckedIn.value = info['checked_in'] ?? false;
      // 从接口获取连续签到天数
      streakDays.value = info['streak_days'] ?? 0;
      // 从接口获取签到记录
      final dates = info['checkin_dates'];
      if (dates is List) {
        checkInDates.value = List<String>.from(dates);
      }
    }
  }

  /// 加载VIP套餐
  Future<void> loadVIPPlans() async {
    try {
      final plans = await _service.getVIPPlans();
      debugPrint('VIP套餐加载: ${plans.length}个');
      vipPlans.value = plans;
    } catch (e) {
      debugPrint('加载VIP套餐异常: $e');
      vipPlans.clear();
    }
  }

  /// 加载音币充值包
  Future<void> loadCoinPackages() async {
    try {
      final packages = await _service.getCoinPackages();
      debugPrint('音币充值包加载: ${packages.length}个');
      coinPackages.value = packages;
    } catch (e) {
      debugPrint('加载音币充值包异常: $e');
      coinPackages.clear();
    }
  }

  /// 加载AI创作配额
  Future<void> loadAIQuota() async {
    try {
      final quota = await _service.getAIQuota();
      if (quota != null) {
        aiQuota.value = quota;
      }
    } catch (e) {
      debugPrint('加载AI配额异常: $e');
    }
  }

  /// 购买VIP套餐
  Future<void> buyVIP(int planId) async {
    final success = await _service.buyVIP(planId);
    if (success) {
      ToastUtil.showSuccess('购买成功');
      await loadMembershipInfo();
    } else {
      ToastUtil.showError('购买失败，请重试');
    }
  }

  /// 购买音币
  Future<void> buyCoins(int packageId) async {
    final success = await _service.buyCoins(packageId);
    if (success) {
      ToastUtil.showSuccess('充值成功');
      await loadMembershipInfo();
    } else {
      ToastUtil.showError('充值失败，请重试');
    }
  }

  /// 计算连续签到应获得的音币奖励
  /// 规则：第1天10币，第2天15币，第3天20币...第7天50币
  int get checkInReward {
    final day = streakDays.value + 1; // 签到后的天数
    if (day >= 7) return 50;
    return 10 + (day - 1) * 5;
  }

  /// 执行签到
  Future<void> performCheckIn() async {
    if (isCheckedIn.value) return;
    final result = await _service.checkIn();
    if (result != null) {
      isCheckedIn.value = true;
      // 使用接口返回的音币数，或使用本地计算的奖励
      final coins = result['coins'] ?? checkInReward;
      earnedCoins.value = coins;
      streakDays.value = result['streak_days'] ?? streakDays.value + 1;
      // 添加今天的签到记录
      final today = DateTime.now().toString().substring(0, 10);
      if (!checkInDates.contains(today)) {
        checkInDates.add(today);
      }
      // 触发签到成功动画
      showCheckInAnimation.value = true;
      ToastUtil.showSuccess('签到成功！音币 +$coins');
      await loadMembershipInfo();
    } else {
      ToastUtil.showError('签到失败，请重试');
    }
  }

  /// 隐藏签到动画
  void hideCheckInAnimation() {
    showCheckInAnimation.value = false;
  }

  /// 获取用户等级名称
  String get levelName {
    final level = membershipInfo['level'] ?? 0;
    switch (level) {
      case 1: return 'VIP';
      case 2: return 'SVIP';
      default: return '普通用户';
    }
  }

  /// 获取音币余额
  int get coinBalance => membershipInfo['coins'] ?? 0;

  /// 获取会员到期时间
  String get expireTime => membershipInfo['expire_time'] ?? '';

  /// 获取今日AI使用次数
  int get aiUsedToday => aiQuota['used_today'] ?? 0;

  /// 获取今日AI使用上限（-1表示无限）
  int get aiDailyLimit => aiQuota['daily_limit'] ?? 3;

  /// 获取AI配额显示文本
  String get aiQuotaText {
    if (aiDailyLimit == -1) {
      return '$aiUsedToday/无限';
    }
    return '$aiUsedToday/$aiDailyLimit';
  }

  /// 检查是否还有AI创作配额
  bool get hasAIQuota {
    if (aiDailyLimit == -1) return true;
    return aiUsedToday < aiDailyLimit;
  }

  /// 获取单次AI创作消耗音币数
  int get aiCostPerUse => aiQuota['cost_per_use'] ?? 0;
}
