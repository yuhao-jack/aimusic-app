import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/modules/membership/membership_controller.dart';
import 'package:aimusic_app/utils/toast_util.dart';

/// 积分商城页面 — 余额从会员API获取真实数据
class PointsShopPage extends StatefulWidget {
  const PointsShopPage({super.key});

  @override
  State<PointsShopPage> createState() => _PointsShopPageState();
}

class _PointsShopPageState extends State<PointsShopPage> {
  /// 会员控制器
  MembershipController get _membershipCtrl {
    if (!Get.isRegistered<MembershipController>()) {
      Get.put(MembershipController());
    }
    return Get.find<MembershipController>();
  }

  /// 商品列表
  /// 注意：后端暂无积分商城 API，商品数据为前端硬编码
  /// 待后端 /api/v1/shop/products 接口完成后，改为从接口动态获取
  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'name': '专属头像框',
      'icon': Icons.auto_awesome_rounded,
      'price': 500,
      'color': AppTheme.brandIndigo,
      'description': '炫酷头像框，彰显个性',
    },
    {
      'id': 2,
      'name': '动态特效',
      'icon': Icons.auto_fix_high_rounded,
      'price': 300,
      'color': AppTheme.brandPurple,
      'description': '个人主页动态特效',
    },
    {
      'id': 3,
      'name': 'VIP体验卡3天',
      'icon': Icons.star_rounded,
      'price': 800,
      'color': AppTheme.brandIndigo,
      'description': '体验VIP全部特权',
    },
    {
      'id': 4,
      'name': 'SVIP体验卡1天',
      'icon': Icons.diamond_rounded,
      'price': 600,
      'color': const Color(0xFFFFD700),
      'description': '体验SVIP尊贵特权',
    },
    {
      'id': 5,
      'name': '个性签名色',
      'icon': Icons.palette_rounded,
      'price': 200,
      'color': AppTheme.brandPink,
      'description': '自定义签名颜色',
    },
    {
      'id': 6,
      'name': '作品置顶卡',
      'icon': Icons.push_pin_rounded,
      'price': 1000,
      'color': AppTheme.brandCyan,
      'description': '置顶你的优秀作品',
    },
  ];

  @override
  void initState() {
    super.initState();
    // 加载最新会员信息（含音币余额）
    _membershipCtrl.loadMembershipInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: const Text(
          '积分商城',
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
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppTheme.textWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildBalanceCard(),
            const SizedBox(height: 20),
            _buildProductGrid(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 音币余额卡片 — 从会员API获取真实余额
  Widget _buildBalanceCard() {
    return Obx(() {
      final balance = _membershipCtrl.coinBalance;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                size: 32,
                color: AppTheme.brandIndigo,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前音币余额',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSilver),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$balance',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 商品网格（2列）
  Widget _buildProductGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '兑换商品',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) => _buildProductItem(index),
          ),
        ],
      ),
    );
  }

  /// 单个商品项
  Widget _buildProductItem(int index) {
    final product = _products[index];
    final price = product['price'] as int;
    final color = product['color'] as Color;
    final icon = product['icon'] as IconData;

    return Obx(() {
      final balance = _membershipCtrl.coinBalance;
      final canAfford = balance >= price;
      return GestureDetector(
        onTap: () => _showExchangeConfirm(index),
        child: Container(
          padding: const EdgeInsets.all(16),
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
              // 商品图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              // 商品名称
              Text(
                product['name'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // 商品描述
              Text(
                product['description'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSilver,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // 价格
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: canAfford
                      ? AppTheme.brandIndigo.withValues(alpha: 0.15)
                      : AppTheme.textDarkGray.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 14,
                      color: canAfford ? AppTheme.brandIndigo : AppTheme.textDarkGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$price',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: canAfford ? AppTheme.brandIndigo : AppTheme.textDarkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 兑换确认弹窗 — 兑换功能暂未对接后端，显示提示
  void _showExchangeConfirm(int index) {
    final product = _products[index];
    final price = product['price'] as int;
    final color = product['color'] as Color;
    final icon = product['icon'] as IconData;
    final balance = _membershipCtrl.coinBalance;
    final canAfford = balance >= price;

    Get.defaultDialog(
      title: '确认兑换',
      titleStyle: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600),
      content: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            product['name'] as String,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product['description'] as String,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSilver),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '花费 ',
                style: TextStyle(fontSize: 14, color: AppTheme.textSilver),
              ),
              Icon(Icons.monetization_on_rounded, size: 16, color: AppTheme.brandIndigo),
              Text(
                ' $price',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandIndigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            canAfford ? '余额 $balance · 兑换后剩余 ${balance - price}' : '余额不足（当前 $balance）',
            style: TextStyle(
              fontSize: 12,
              color: canAfford ? AppTheme.textSilver : AppTheme.errorColor,
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.surface3,
      radius: AppTheme.radiusLarge,
      confirm: ElevatedButton(
        onPressed: canAfford
            ? () {
                Get.back();
                // 兑换功能暂未对接后端API
                ToastUtil.showInfo('功能开发中，敬请期待');
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canAfford ? AppTheme.brandIndigo : AppTheme.textDarkGray,
          foregroundColor: AppTheme.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
        ),
        child: Text(canAfford ? '确认兑换' : '余额不足'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('取消', style: TextStyle(color: AppTheme.textSilver)),
      ),
    );
  }
}
