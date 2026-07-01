import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/global/user_controller.dart';
import 'package:aimusic_app/utils/api_config.dart';
import 'package:aimusic_app/utils/toast_util.dart';

/// 邀请好友页面
class InvitePage extends StatelessWidget {
  InvitePage({super.key});

  /// 从用户信息获取邀请码，无数据时显示占位
  String get _inviteCode {
    final code = UserController.to.userInfo['invite_code'] ?? '';
    return code.isNotEmpty ? code : '暂无邀请码';
  }

  /// 邀请链接基于邀请码动态生成
  String get _inviteLink => '${ApiConfig.shareBaseUrl}/invite/$_inviteCode';

  /// 每位好友奖励音币数
  static int _rewardPerFriend = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Text(
          '邀请好友',
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
            _buildRewardBanner(),
            SizedBox(height: 20),
            _buildInviteCodeSection(),
            SizedBox(height: 16),
            _buildInviteLinkSection(),
            SizedBox(height: 20),
            _buildShareButtons(),
            SizedBox(height: 24),
            _buildRewardRules(),
            SizedBox(height: 24),
            _buildInvitedFriendsList(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 奖励横幅
  Widget _buildRewardBanner() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E99A4), Color(0xFFB0A898)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          children: [
            Icon(
              Icons.card_giftcard_rounded,
              size: 40,
              color: AppTheme.textWhite,
            ),
            SizedBox(height: 12),
            Text(
              '邀请好友 得音币',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '邀请好友注册即获$_rewardPerFriend音币奖励',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textWhite.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.textWhite.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              ),
              child: Text(
                '多邀多得，奖励无上限',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 邀请码区域
  Widget _buildInviteCodeSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface3.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: AppTheme.borderSubtle.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '我的邀请码',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSilver,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: AppTheme.brandIndigo.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _inviteCode,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandIndigo,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                _buildCopyButton(_inviteCode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 邀请链接区域
  Widget _buildInviteLinkSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface3.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: AppTheme.borderSubtle.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '邀请链接',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSilver,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _inviteLink,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSilver,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 12),
                _buildCopyButton(_inviteLink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 复制按钮
  Widget _buildCopyButton(String text) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        Get.snackbar(
          '已复制',
          '内容已复制到剪贴板',
          backgroundColor: AppTheme.successColor.withValues(alpha: 0.9),
          colorText: AppTheme.textWhite,
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 1),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.brandIndigo.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_rounded, size: 16, color: AppTheme.brandIndigo),
            SizedBox(width: 4),
            Text(
              '复制',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.brandIndigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分享按钮组
  Widget _buildShareButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildShareBtn(
              icon: Icons.wechat_rounded,
              label: '微信分享',
              color: Color(0xFF07C160),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildShareBtn(
              icon: Icons.link_rounded,
              label: '复制链接',
              color: AppTheme.brandIndigo,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildShareBtn(
              icon: Icons.qr_code_rounded,
              label: '生成海报',
              color: AppTheme.brandPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareBtn({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        // 复制邀请链接到剪贴板
        Clipboard.setData(ClipboardData(text: _inviteLink));
        ToastUtil.showSuccess('链接已复制');
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 奖励规则
  Widget _buildRewardRules() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '奖励规则',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
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
                _RuleItem(icon: Icons.check_circle_outline, text: '好友通过你的邀请码或链接注册成功'),
                _RuleItem(icon: Icons.check_circle_outline, text: '你和好友各获得100音币奖励'),
                _RuleItem(icon: Icons.check_circle_outline, text: '邀请人数无上限，多邀多得'),
                _RuleItem(icon: Icons.check_circle_outline, text: '音币可用于充值VIP或兑换商品'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 已邀请好友列表（暂无API，显示空状态）
  Widget _buildInvitedFriendsList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已邀请好友',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.surface3.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            ),
            child: Center(
              child: Text(
                '还没有邀请好友，快去分享吧',
                style: TextStyle(color: AppTheme.textSilver),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final String text;

  _RuleItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.brandIndigo),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: AppTheme.textSilver),
            ),
          ),
        ],
      ),
    );
  }
}
