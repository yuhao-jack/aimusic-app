import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/ai_service.dart';
import 'package:aimusic_app/modules/membership/membership_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';

class LyricCreateController extends GetxController {
  final AIService aiService = Get.find<AIService>();

  // Input fields
  final promptController = TextEditingController();
  
  // 默认情绪列表，接口失败时兜底
  static final _defaultEmotions = ['开心', '悲伤', '活力', '忧郁', '浪漫'];
  // 默认风格列表，接口失败时兜底
  static final _defaultStyles = ['流行', '摇滚', '嘻哈', '节奏布鲁斯', '电子', '民谣'];

  // 情绪和风格的可选项（从后台配置获取）
  final RxList<String> emotionOptions = <String>[].obs;
  final RxList<String> styleOptions = <String>[].obs;

  // Selection states
  RxString selectedMood = ''.obs;
  RxString selectedGenre = ''.obs;
  RxString selectedLanguage = '中文'.obs;
  
  // UI states
  RxBool isGenerating = false.obs;
  RxBool showResult = false.obs;
  RxString progressText = ''.obs;
  RxString generatedLyric = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // 初始化默认值，然后从后台拉取最新配置
    emotionOptions.value = _defaultEmotions;
    styleOptions.value = _defaultStyles;
    _loadPublicConfig();
  }

  /// 从后台获取公开配置（情绪/风格列表），失败时使用默认值
  Future<void> _loadPublicConfig() async {
    try {
      final config = await aiService.getPublicConfig();
      if (config != null) {
        if (config['music_emotions'] != null && (config['music_emotions'] as List).isNotEmpty) {
          emotionOptions.value = List<String>.from(config['music_emotions']);
        }
        if (config['music_styles'] != null && (config['music_styles'] as List).isNotEmpty) {
          styleOptions.value = List<String>.from(config['music_styles']);
        }
      }
    } catch (e) {
      debugPrint('加载公开配置失败，使用默认值: $e');
    }
  }

  // ===== Generate Lyric =====
  Future<void> generateLyric() async {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      Get.snackbar(
        '提示', 
        '请输入关键词',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: AppTheme.textWhite,
      );
      return;
    }

    // 检查配额
    if (!await _checkQuota()) return;

    isGenerating.value = true;
    showResult.value = false;
    generatedLyric.value = '';
    progressText.value = '正在生成歌词...';

    try {
      // 真实API调用
      final result = await aiService.generateLyric(
        prompt: prompt,
        style: selectedGenre.value.isNotEmpty ? selectedGenre.value : '流行',
        emotion: selectedMood.value.isNotEmpty ? selectedMood.value : '开心',
        lang: '中文',
      );
      
      if (result != null) {
        generatedLyric.value = result['lyric'] ?? '';
        showResult.value = true;
        Get.snackbar(
          '成功', 
          '歌词生成完成',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.successColor,
          colorText: AppTheme.textWhite,
        );
      } else {
        Get.snackbar(
          '错误', 
          '生成失败',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.errorColor,
          colorText: AppTheme.textWhite,
        );
      }
    } catch (e) {
      Get.snackbar(
        '错误', 
        '生成失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorColor,
        colorText: AppTheme.textWhite,
      );
    } finally {
      isGenerating.value = false;
    }
  }

  // ===== Check Quota =====
  Future<bool> _checkQuota() async {
    // 确保会员控制器已注册
    if (!Get.isRegistered<MembershipController>()) {
      Get.put(MembershipController());
    }
    final membershipCtrl = Get.find<MembershipController>();
    
    // 加载最新配额信息
    await membershipCtrl.loadAIQuota();
    
    // 检查是否有配额
    if (!membershipCtrl.hasAIQuota) {
      // 配额不足，检查音币
      final cost = membershipCtrl.aiCostPerUse;
      final balance = membershipCtrl.coinBalance;
      
      if (cost > 0 && balance < cost) {
        // 音币不足
        _showInsufficientCoinsDialog();
        return false;
      }
      
      // 有音币但无配额，提示扣费确认
      if (cost > 0) {
        return await _showCostConfirmDialog(cost, balance);
      }
      
      // 无配额且无扣费机制
      Get.snackbar(
        '提示',
        '今日AI创作次数已用完',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: AppTheme.textWhite,
      );
      return false;
    }
    
    // 有配额，检查是否需要扣费
    final cost = membershipCtrl.aiCostPerUse;
    if (cost > 0) {
      final balance = membershipCtrl.coinBalance;
      if (balance < cost) {
        _showInsufficientCoinsDialog();
        return false;
      }
      return await _showCostConfirmDialog(cost, balance);
    }
    
    return true;
  }

  // ===== 显示扣费确认弹窗 =====
  Future<bool> _showCostConfirmDialog(int cost, int balance) async {
    final result = await Get.dialog<bool>(
      Dialog(
        backgroundColor: AppTheme.surface3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(
            color: AppTheme.borderSubtle.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppTheme.brandIndigo.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.monetization_on_rounded,
                  size: 28,
                  color: AppTheme.brandIndigo,
                ),
              ),
              SizedBox(height: 16),
              // 标题
              Text(
                'AI创作扣费确认',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 12),
              // 扣费信息
              Text(
                '本次创作将消耗 $cost 音币',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '当前余额: $balance 音币',
                style: TextStyle(
                  fontSize: 13,
                  color: balance >= cost ? AppTheme.textSilver : AppTheme.errorColor,
                ),
              ),
              SizedBox(height: 24),
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSilver,
                        side: BorderSide(color: AppTheme.borderGray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('取消', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: AppTheme.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        '确认创作',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  // ===== 显示音币不足弹窗 =====
  void _showInsufficientCoinsDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(
            color: AppTheme.borderSubtle.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.errorColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 28,
                  color: AppTheme.errorColor,
                ),
              ),
              SizedBox(height: 16),
              // 标题
              Text(
                '音币不足',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 12),
              // 提示
              Text(
                '音币余额不足，请先充值',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSilver,
                ),
              ),
              SizedBox(height: 24),
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSilver,
                        side: BorderSide(color: AppTheme.borderGray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('取消', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.toNamed(AppRoutes.membership);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: AppTheme.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        '去充值',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Cancel Generation =====
  void cancelGeneration() {
    isGenerating.value = false;
    Get.snackbar(
      '取消', 
      '已取消生成',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.warningColor,
      colorText: AppTheme.textWhite,
    );
  }

  // ===== Copy Lyric =====
  void copyLyric() {
    final lyric = generatedLyric.value;
    if (lyric.isEmpty) {
      Get.snackbar(
        '提示',
        '没有可复制的歌词',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: AppTheme.textWhite,
      );
      return;
    }
    // 实际复制到剪贴板
    Clipboard.setData(ClipboardData(text: lyric));
    Get.snackbar(
      '已复制',
      '歌词已复制到剪贴板',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successColor,
      colorText: AppTheme.textWhite,
    );
  }

  // ===== Edit Lyric =====
  void editLyric() {
    showResult.value = false;
  }

  // ===== Regenerate Lyric =====
  void regenerateLyric() {
    showResult.value = false;
    generateLyric();
  }

  @override
  void onClose() {
    promptController.dispose();
    super.onClose();
  }
}
