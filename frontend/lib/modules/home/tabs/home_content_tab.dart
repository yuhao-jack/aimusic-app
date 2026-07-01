import 'package:flutter/material.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/modules/home/tabs/recommend_tab.dart';
import 'package:aimusic_app/modules/home/tabs/following_tab.dart';

/// 首页内容 Tab 切换容器
/// 包含"推荐"和"关注"两个子 Tab
/// 视觉风格：简洁下划线指示器，更精致的分层背景
class HomeContentTab extends StatefulWidget {
  HomeContentTab({super.key});

  @override
  State<HomeContentTab> createState() => _HomeContentTabState();
}

class _HomeContentTabState extends State<HomeContentTab> with TickerProviderStateMixin {
  late final TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        // 状态栏占位
        SizedBox(height: topPadding),
        // 子 Tab 切换栏
        Container(
          margin: EdgeInsets.fromLTRB(20, 4, 20, 0),
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
          child: TabBar(
            controller: _subTabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppTheme.textWhite,
            unselectedLabelColor: AppTheme.textSilver,
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: '推荐'),
              Tab(text: '关注'),
            ],
          ),
        ),
        // 内容区域
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            physics: BouncingScrollPhysics(),
            children: [
              RecommendTab(),
              FollowingTab(),
            ],
          ),
        ),
      ],
    );
  }
}
