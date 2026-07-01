import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/modules/membership/membership_controller.dart';

/// 每日任务页面 — 对接后端签到API获取真实签到状态
class DailyTasksPage extends StatefulWidget {
  DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  /// 任务列表（前端展示，签到状态从后端获取）
  /// 注意：后端暂无每日任务配置 API，任务列表和奖励数值为前端硬编码
  /// 待后端 /api/v1/tasks/daily 接口完成后，改为从接口动态获取
  final List<Map<String, dynamic>> _tasks = [
    {
      'id': 1,
      'title': '每日签到',
      'icon': Icons.calendar_today_rounded,
      'reward': 10,
      'completed': false,
      'claimed': false,
    },
    {
      'id': 2,
      'title': '听3首歌',
      'icon': Icons.headphones_rounded,
      'current': 1,
      'target': 3,
      'reward': 10,
      'completed': false,
      'claimed': false,
    },
    {
      'id': 3,
      'title': '发1条动态',
      'icon': Icons.edit_note_rounded,
      'current': 0,
      'target': 1,
      'reward': 20,
      'completed': false,
      'claimed': false,
    },
    {
      'id': 4,
      'title': '点赞5首歌',
      'icon': Icons.favorite_rounded,
      'current': 3,
      'target': 5,
      'reward': 10,
      'completed': false,
      'claimed': false,
    },
  ];

  /// 是否正在签到
  bool _isCheckingIn = false;

  /// 会员控制器
  MembershipController get _membershipCtrl {
    if (!Get.isRegistered<MembershipController>()) {
      Get.put(MembershipController());
    }
    return Get.find<MembershipController>();
  }

  @override
  void initState() {
    super.initState();
    // 同步后端签到状态到前端任务列表
    _syncCheckInStatus();
  }

  /// 从后端获取真实签到状态，同步到任务列表
  void _syncCheckInStatus() async {
    await _membershipCtrl.loadMembershipInfo();
    final isCheckedIn = _membershipCtrl.isCheckedIn.value;
    final streakDays = _membershipCtrl.streakDays.value;
    final reward = _membershipCtrl.checkInReward;

    setState(() {
      // 更新签到任务状态
      _tasks[0]['completed'] = isCheckedIn;
      _tasks[0]['claimed'] = isCheckedIn;
      _tasks[0]['reward'] = reward;
      // 如果已签到，记录连续天数
      if (isCheckedIn) {
        _tasks[0]['streak_days'] = streakDays;
      }
    });
  }

  /// 今日总获得音币
  int get _totalEarned {
    int total = 0;
    for (final task in _tasks) {
      if (task['claimed'] == true) {
        total += task['reward'] as int;
      }
    }
    return total;
  }

  /// 领取签到奖励（调用后端签到API）
  Future<void> _claimCheckInReward() async {
    if (_isCheckingIn) return;
    setState(() => _isCheckingIn = true);

    try {
      await _membershipCtrl.performCheckIn();
      // 签到成功后同步状态
      final reward = _membershipCtrl.checkInReward;
      setState(() {
        _tasks[0]['completed'] = true;
        _tasks[0]['claimed'] = true;
        _tasks[0]['reward'] = reward;
      });
    } catch (e) {
      debugPrint('签到失败: $e');
    } finally {
      setState(() => _isCheckingIn = false);
    }
  }

  /// 领取其他任务奖励（前端模拟）
  void _claimTaskReward(int index) {
    final task = _tasks[index];
    if (task['completed'] != true || task['claimed'] == true) return;

    setState(() {
      _tasks[index]['claimed'] = true;
    });

    Get.snackbar(
      '领取成功',
      '获得${task['reward']}音币',
      backgroundColor: AppTheme.successColor.withValues(alpha: 0.9),
      colorText: AppTheme.textWhite,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Text(
          '每日任务',
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
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            _buildTodaySummary(),
            SizedBox(height: 20),
            _buildTaskList(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 今日音币总览
  Widget _buildTodaySummary() {
    final completedCount = _tasks.where((t) => t['completed'] == true).length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.brandIndigo.withValues(alpha: 0.12),
              AppTheme.brandPurple.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.brandIndigo.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.monetization_on_rounded, size: 22, color: AppTheme.brandIndigo),
                    SizedBox(width: 6),
                    Text(
                      '$_totalEarned',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '今日获得音币',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSilver),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.borderSubtle.withValues(alpha: 0.4),
            ),
            Column(
              children: [
                Text(
                  '$completedCount/${_tasks.length}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '已完成任务',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSilver),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 任务列表
  Widget _buildTaskList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日任务',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          SizedBox(height: 12),
          ...List.generate(_tasks.length, (i) => _buildTaskItem(i)),
        ],
      ),
    );
  }

  /// 单个任务项
  Widget _buildTaskItem(int index) {
    final task = _tasks[index];
    final current = task['current'] as int? ?? 0;
    final target = task['target'] as int? ?? 1;
    final reward = task['reward'] as int;
    final isCompleted = task['completed'] == true;
    final isClaimed = task['claimed'] == true;
    final progress = target > 0 ? current / target : 0.0;
    final icon = task['icon'] as IconData;
    final isCheckInTask = task['id'] == 1;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(
          color: isClaimed
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : AppTheme.borderSubtle.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 任务图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isClaimed
                      ? AppTheme.successColor.withValues(alpha: 0.15)
                      : AppTheme.brandIndigo.withValues(alpha: 0.12),
                ),
                child: Icon(
                  isClaimed ? Icons.check_rounded : icon,
                  size: 22,
                  color: isClaimed ? AppTheme.successColor : AppTheme.brandIndigo,
                ),
              ),
              SizedBox(width: 14),
              // 任务信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isClaimed ? AppTheme.textSilver : AppTheme.textWhite,
                        decoration: isClaimed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '奖励 $reward 音币',
                      style: TextStyle(
                        fontSize: 12,
                        color: isClaimed ? AppTheme.textDarkGray : AppTheme.textSilver,
                      ),
                    ),
                  ],
                ),
              ),
              // 领取按钮 / 进度
              if (isClaimed)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  ),
                  child: Text(
                    '已领取',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.successColor,
                    ),
                  ),
                )
              else if (isCheckInTask)
                // 签到任务 — 调用后端签到API
                GestureDetector(
                  onTap: _isCheckingIn ? null : _claimCheckInReward,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.brandIndigo,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    ),
                    child: _isCheckingIn
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppTheme.textWhite,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '签到',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textWhite,
                            ),
                          ),
                  ),
                )
              else if (isCompleted)
                GestureDetector(
                  onTap: () => _claimTaskReward(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.brandIndigo,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    ),
                    child: Text(
                      '领取',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  '$current/$target',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSilver,
                  ),
                ),
            ],
          ),
          // 进度条（未完成时显示）
          if (!isCompleted && !isCheckInTask) ...[
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.surface2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppTheme.successColor : AppTheme.brandIndigo,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
