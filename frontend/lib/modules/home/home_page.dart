import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/home/tabs/home_content_tab.dart';
import 'package:aimusic_app/modules/together/together_page.dart';
import 'package:aimusic_app/modules/together/together_controller.dart';
import 'package:aimusic_app/modules/profile/profile_page.dart';
import 'package:aimusic_app/modules/player/player_controller.dart';
import 'package:aimusic_app/widgets/mini_player.dart';

import 'package:aimusic_app/theme/app_theme.dart';

/// 主页面 - 底部导航容器
/// 视觉风格：无 indicator，选中时图标+文字整体高亮为 primaryColor
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    // 确保 PlayerController 已注册
    if (!Get.isRegistered<PlayerController>()) {
      Get.put(PlayerController());
    }
    // 确保 TogetherController 已注册（Tab页需要）
    if (!Get.isRegistered<TogetherController>()) {
      Get.put(TogetherController());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          HomeContentTab(),
          TogetherPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderSubtle.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Material(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabController,
              // No indicator - use icon+text color change instead
              indicator: const BoxDecoration(),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppTheme.brandIndigo,
              unselectedLabelColor: AppTheme.textLightGray,
              labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                _navTab(Icons.home_outlined, Icons.home_rounded, '首页', 0),
                _navTab(Icons.explore_outlined, Icons.explore_rounded, '社区', 1),
                _navTab(Icons.person_outline_rounded, Icons.person_rounded, '我的', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navTab(IconData outline, IconData filled, String label, int index) {
    final isSelected = _tabController.index == index;
    return Tab(
      icon: Icon(isSelected ? filled : outline, size: 24),
      text: label,
    );
  }
}
