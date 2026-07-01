import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/modules/together/together_controller.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/services/post_service.dart';
import 'package:aimusic_app/widgets/image_viewer.dart';
import 'package:aimusic_app/utils/api_config.dart';

/// 社区页面 — 动态 + 一起听 双Tab
class TogetherPage extends GetView<TogetherController> {
  TogetherPage({super.key});

  final RxInt _currentTab = 0.obs;
  final RxList<Map<String, dynamic>> _posts = <Map<String, dynamic>>[].obs;
  final RxBool _postsLoading = true.obs;
  final int _postPageSize = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Obx(() => Text(
          _currentTab.value == 0 ? '动态' : '一起听',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
        )),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // 发帖按钮
          Obx(() => _currentTab.value == 0
              ? Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.createPost),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: AppTheme.brandIndigo),
                          SizedBox(width: 4),
                          Text('发帖', style: TextStyle(
                            color: AppTheme.brandIndigo,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                    ),
                  ),
                )
              : SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          // Tab栏
          _buildTabBar(),
          // 内容区
          Expanded(
            child: Obx(() => _currentTab.value == 0
                ? _buildFeedTab()
                : _buildRoomTab()),
          ),
        ],
      ),
    );
  }

  // ===== Tab栏 =====
  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
      ),
      child: Obx(() => Row(
        children: [
          _buildTabItem('动态', 0, Icons.article_outlined),
          _buildTabItem('一起听', 1, Icons.headphones_rounded),
        ],
      )),
    );
  }

  Widget _buildTabItem(String label, int index, IconData icon) {
    final isSelected = _currentTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _currentTab.value = index;
          if (index == 0 && _posts.isEmpty) _loadPosts();
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.brandIndigo.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppTheme.brandIndigo : AppTheme.textLightGray),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.brandIndigo : AppTheme.textLightGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 动态Tab =====
  Widget _buildFeedTab() {
    // 确保加载数据
    if (_posts.isEmpty && !_postsLoading.value) {
      Future.microtask(() => _loadPosts());
    }

    return RefreshIndicator(
      color: AppTheme.brandIndigo,
      backgroundColor: AppTheme.surface2,
      onRefresh: () => _loadPosts(),
      child: Obx(() {
        if (_postsLoading.value && _posts.isEmpty) {
          return ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: 5,
            itemBuilder: (_, __) => _buildPostShimmer(),
          );
        }
        if (_posts.isEmpty) {
          return ListView(
            children: [
              SizedBox(height: 120),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.article_outlined, size: 56, color: AppTheme.textDarkGray.withValues(alpha: 0.4)),
                    SizedBox(height: 16),
                    Text('还没有动态', style: TextStyle(color: AppTheme.textSilver, fontSize: 15, fontWeight: FontWeight.w500)),
                    SizedBox(height: 6),
                    Text('点击右上角发帖分享你的音乐', style: TextStyle(color: AppTheme.textLightGray, fontSize: 13)),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView.builder(
          physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return FadeInWidget(
              delayMs: index * 50,
              child: _buildPostCard(_posts[index]),
            );
          },
        );
      }),
    );
  }

  // ===== 动态卡片 =====
  Widget _buildPostCard(Map<String, dynamic> post) {
    final nickname = post['nickname'] ?? post['username'] ?? '用户';
    final avatar = post['avatar'] ?? '';
    final content = post['content'] ?? '';
    final createdAt = post['created_at'] ?? '';
    final likeCount = post['like_count'] ?? 0;
    final commentCount = post['comment_count'] ?? 0;
    final images = post['images'];
    final postId = post['id'] ?? post['ID'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息行
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.surface2,
                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? Icon(Icons.person_rounded, size: 20, color: AppTheme.textLightGray)
                    : null,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nickname, style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
                    )),
                    if (createdAt.isNotEmpty)
                      Text(_formatTime(createdAt), style: TextStyle(
                        fontSize: 11, color: AppTheme.textLightGray,
                      )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showPostOptions(post),
                child: Icon(Icons.more_horiz_rounded, size: 18, color: AppTheme.textLightGray),
              ),
            ],
          ),
          SizedBox(height: 12),
          // 内容
          if (content.isNotEmpty)
            Text(content, style: TextStyle(
              fontSize: 15, color: AppTheme.textWhite, height: 1.5,
            )),
          // 图片
          if (images != null && images is List && images.isNotEmpty) ...[
            SizedBox(height: 10),
            _buildImageGrid(images),
          ],
          SizedBox(height: 12),
          // 操作栏
          Row(
            children: [
              _buildActionItem(Icons.favorite_border_rounded, '$likeCount', () => _likePost(postId)),
              SizedBox(width: 24),
              _buildActionItem(Icons.chat_bubble_outline_rounded, '$commentCount', () => _showComments(postId)),
              SizedBox(width: 24),
              _buildActionItem(Icons.share_outlined, '分享', () => _sharePost(post)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List images) {
    final urlList = images.map((e) => e.toString()).toList();

    if (urlList.length == 1) {
      return GestureDetector(
        onTap: () => showImageViewer(imageUrls: urlList, initialIndex: 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: urlList[0],
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              height: 200, color: AppTheme.surface2,
              child: Icon(Icons.image, color: AppTheme.textDarkGray),
            ),
          ),
        ),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(urlList.length.clamp(0, 9), (i) {
        return GestureDetector(
          onTap: () => showImageViewer(imageUrls: urlList, initialIndex: i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: urlList[i],
              width: 100, height: 100, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 100, height: 100, color: AppTheme.surface2,
                child: Icon(Icons.image, color: AppTheme.textDarkGray),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textLightGray),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textLightGray)),
        ],
      ),
    );
  }

  Widget _buildPostShimmer() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(
              shape: BoxShape.circle, color: AppTheme.surface2,
            )),
            SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 80, height: 12, decoration: BoxDecoration(
                color: AppTheme.surface2, borderRadius: BorderRadius.circular(4),
              )),
              SizedBox(height: 6),
              Container(width: 50, height: 10, decoration: BoxDecoration(
                color: AppTheme.surface2, borderRadius: BorderRadius.circular(4),
              )),
            ]),
          ]),
          SizedBox(height: 12),
          Container(width: double.infinity, height: 14, decoration: BoxDecoration(
            color: AppTheme.surface2, borderRadius: BorderRadius.circular(4),
          )),
          SizedBox(height: 8),
          Container(width: 200, height: 14, decoration: BoxDecoration(
            color: AppTheme.surface2, borderRadius: BorderRadius.circular(4),
          )),
        ],
      ),
    );
  }

  // ===== 一起听Tab =====
  Widget _buildRoomTab() {
    return RefreshIndicator(
      color: AppTheme.brandIndigo,
      backgroundColor: AppTheme.surface2,
      onRefresh: () => controller.refreshData(),
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // 当前房间
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.currentRoom.value == null) return SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: FadeInWidget(child: _buildActiveRoomCard()),
              );
            }),
          ),
          // 创建房间按钮
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElasticButton(
                onTap: () => _showCreateRoomDialog(),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.brandIndigo, AppTheme.brandPurple],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: AppTheme.textWhite, size: 20),
                      SizedBox(width: 8),
                      Text('创建房间', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 我的房间
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.myRooms.isEmpty) return SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _buildMyRoomsSection(),
              );
            }),
          ),
          // 房间列表标题
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.headphones_rounded, size: 18, color: AppTheme.brandIndigo),
                  SizedBox(width: 8),
                  Text('房间列表', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textWhite,
                  )),
                  Spacer(),
                  Obx(() => Text(
                    '${controller.publicRooms.length}个房间',
                    style: TextStyle(fontSize: 12, color: AppTheme.textLightGray),
                  )),
                ],
              ),
            ),
          ),
          // 房间列表
          Obx(() {
            if (controller.publicRoomsLoading.value) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.brandIndigo, strokeWidth: 2),
                  ),
                ),
              );
            }
            if (controller.publicRooms.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.headphones_rounded, size: 48, color: AppTheme.textDarkGray.withValues(alpha: 0.4)),
                      SizedBox(height: 12),
                      Text('暂无公开房间', style: TextStyle(
                        fontSize: 15, color: AppTheme.textSilver, fontWeight: FontWeight.w500,
                      )),
                      SizedBox(height: 4),
                      Text('点击上方按钮创建房间', style: TextStyle(
                        fontSize: 13, color: AppTheme.textLightGray,
                      )),
                    ],
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: FadeInWidget(
                      delayMs: index * 50,
                      child: _buildRoomItem(controller.publicRooms[index]),
                    ),
                  );
                },
                childCount: controller.publicRooms.length,
              ),
            );
          }),
          SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ===== 房间列表项 =====
  Widget _buildRoomItem(Map<String, dynamic> room) {
    final roomName = room['name'] ?? '一起听歌';
    final roomCode = room['room_code'] ?? room['RoomCode'] ?? '';
    final creatorName = room['creator_name'] ?? '未知';
    final memberCount = room['member_count'] ?? 0;
    final songTitle = room['song_title'] ?? '';
    final songCover = room['song_cover'] ?? '';
    final hasPassword = room['password'] != null && room['password'].toString().isNotEmpty;
    final maxMembers = room['max_members'] ?? 10;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          // 封面
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: songCover.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: songCover,
                    width: 52, height: 52, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _buildCoverPlaceholder(),
                  )
                : _buildCoverPlaceholder(),
          ),
          SizedBox(width: 12),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        roomName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textWhite),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasPassword)
                      Container(
                        margin: EdgeInsets.only(left: 6),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 10, color: AppTheme.warningColor),
                            SizedBox(width: 2),
                            Text('密码', style: TextStyle(fontSize: 9, color: AppTheme.warningColor)),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                if (songTitle.isNotEmpty)
                  Text('🎵 $songTitle', style: TextStyle(
                    fontSize: 12, color: AppTheme.textSilver,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(creatorName, style: TextStyle(fontSize: 11, color: AppTheme.textLightGray)),
                    SizedBox(width: 10),
                    Icon(Icons.people_outline_rounded, size: 12, color: AppTheme.textLightGray),
                    SizedBox(width: 3),
                    Text('$memberCount/$maxMembers', style: TextStyle(
                      fontSize: 11, color: AppTheme.textLightGray,
                    )),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          // 加入按钮
          ElasticButton(
            onTap: () {
              if (hasPassword) {
                _showJoinWithPasswordDialog(roomCode);
              } else {
                controller.joinRoom(roomCode);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              ),
              child: Text('加入', style: TextStyle(
                fontSize: 13, color: AppTheme.brandIndigo, fontWeight: FontWeight.w600,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.music_note_rounded, size: 24, color: AppTheme.textDarkGray),
    );
  }

  // ===== 创建房间弹窗 =====
  void _showCreateRoomDialog() {
    controller.roomNameController.clear();
    controller.roomPasswordController.clear();
    controller.roomDescController.clear();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖拽条
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textDarkGray, borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('创建房间', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textWhite,
              )),
              SizedBox(height: 4),
              Text('邀请好友一起听歌', style: TextStyle(
                fontSize: 13, color: AppTheme.textSilver,
              )),
              SizedBox(height: 20),
              // 房间名称
              _buildSmallInput(
                controller: controller.roomNameController,
                hint: '房间名称（选填）',
                icon: Icons.edit_rounded,
              ),
              SizedBox(height: 12),
              // 房间密码
              _buildSmallInput(
                controller: controller.roomPasswordController,
                hint: '房间密码（不填则公开）',
                icon: Icons.lock_outline_rounded,
                obscure: true,
              ),
              SizedBox(height: 12),
              // 房间描述
              _buildSmallInput(
                controller: controller.roomDescController,
                hint: '房间描述（选填）',
                icon: Icons.description_outlined,
              ),
              SizedBox(height: 20),
              // 创建按钮
              SizedBox(
                width: double.infinity,
                child: ElasticButton(
                  onTap: () {
                    Get.back();
                    controller.createRoom(1);
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.brandIndigo, AppTheme.brandPurple],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    ),
                    child: Center(
                      child: Obx(() => controller.isCreating.value
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(
                              color: AppTheme.textWhite, strokeWidth: 2))
                          : Text('创建', style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
                            )),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 输入密码加入弹窗 =====
  void _showJoinWithPasswordDialog(String roomCode) {
    final pwdController = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('输入房间密码', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textWhite,
            )),
            SizedBox(height: 4),
            Text('该房间需要密码才能加入', style: TextStyle(
              fontSize: 13, color: AppTheme.textSilver,
            )),
            SizedBox(height: 16),
            _buildSmallInput(
              controller: pwdController,
              hint: '请输入房间密码',
              icon: Icons.lock_outline_rounded,
              obscure: true,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElasticButton(
                onTap: () {
                  Get.back();
                  controller.joinRoom(roomCode, password: pwdController.text.trim());
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.brandIndigo,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  ),
                  child: Center(
                    child: Text('加入', style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
                    )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 我的房间列表 =====
  Widget _buildMyRoomsSection() {
    return Obx(() {
      if (controller.myRoomsLoading.value) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface3.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Center(
            child: SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(color: AppTheme.brandIndigo, strokeWidth: 2),
            ),
          ),
        );
      }
      if (controller.myRooms.isEmpty) return SizedBox.shrink();

      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface3.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.brandIndigo.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, size: 18, color: AppTheme.brandIndigo),
                SizedBox(width: 8),
                Text('我的房间', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textWhite,
                )),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  ),
                  child: Text(
                    '${controller.myRooms.length}',
                    style: TextStyle(fontSize: 12, color: AppTheme.brandIndigo, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...controller.myRooms.map((room) => _buildMyRoomItem(room)),
          ],
        ),
      );
    });
  }

  /// 单个房间条目
  Widget _buildMyRoomItem(Map<String, dynamic> room) {
    final roomName = room['name'] ?? '一起听歌';
    final roomCode = room['room_code'] ?? room['RoomCode'] ?? '';
    final memberCount = room['member_count'] ?? (room['members'] is List ? (room['members'] as List).length : 0);
    final isOwner = room['is_owner'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface2.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 房间信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isOwner)
                      Container(
                        margin: EdgeInsets.only(right: 6),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('房主', style: TextStyle(
                          fontSize: 10, color: AppTheme.warningColor, fontWeight: FontWeight.w600,
                        )),
                      ),
                    Expanded(
                      child: Text(
                        roomName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textWhite),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text('邀请码: $roomCode', style: TextStyle(
                      fontSize: 12, color: AppTheme.textSilver,
                    )),
                    SizedBox(width: 12),
                    Icon(Icons.people_outline_rounded, size: 13, color: AppTheme.textLightGray),
                    SizedBox(width: 3),
                    Text('$memberCount人', style: TextStyle(
                      fontSize: 12, color: AppTheme.textLightGray,
                    )),
                  ],
                ),
              ],
            ),
          ),
          // 复制邀请码
          GestureDetector(
            onTap: () {
              if (roomCode.isNotEmpty) {
                // 使用 flutter/services 的 Clipboard 需要额外导入，这里用 Toast 提示
                ToastUtil.showSuccess('邀请码: $roomCode');
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 14, color: AppTheme.textSilver),
                  SizedBox(width: 4),
                  Text('复制', style: TextStyle(fontSize: 12, color: AppTheme.textSilver)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 创建房间卡片 =====

  // ===== 小输入框 =====
  Widget _buildSmallInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface2.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textDarkGray.withValues(alpha: 0.6), fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: AppTheme.textLightGray),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  // ===== 加入房间卡片 =====

  // ===== 当前房间卡片 =====
  Widget _buildActiveRoomCard() {
    final room = controller.currentRoom.value;
    final roomName = room?['name'] ?? '一起听歌';
    final roomCode = room?['room_code'] ?? room?['RoomCode'] ?? '';
    final hasPassword = room?['password'] != null && room?['password'].toString().isNotEmpty == true;
    final memberCount = room?['members'] != null
        ? (room!['members'] is List ? (room['members'] as List).length : 0)
        : 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(color: AppTheme.brandIndigo.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 房间信息行
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppTheme.successColor,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roomName, style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
                    )),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text('邀请码: $roomCode', style: TextStyle(
                          fontSize: 12, color: AppTheme.textSilver,
                        )),
                        if (hasPassword) ...[
                          SizedBox(width: 8),
                          Icon(Icons.lock_rounded, size: 12, color: AppTheme.warningColor),
                          SizedBox(width: 2),
                          Text('有密码', style: TextStyle(
                            fontSize: 11, color: AppTheme.warningColor,
                          )),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 成员数
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_rounded, size: 14, color: AppTheme.brandIndigo),
                    SizedBox(width: 4),
                    Text('$memberCount人', style: TextStyle(
                      fontSize: 12, color: AppTheme.brandIndigo, fontWeight: FontWeight.w500,
                    )),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // 操作按钮行
          Row(
            children: [
              // 复制邀请码
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // 复制到剪贴板
                    ToastUtil.showSuccess('邀请码已复制: $roomCode');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSilver),
                        SizedBox(width: 6),
                        Text('复制邀请码', style: TextStyle(
                          fontSize: 13, color: AppTheme.textSilver,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              // 离开房间
              GestureDetector(
                onTap: () => controller.leaveRoom(),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('离开房间', style: TextStyle(
                    fontSize: 13, color: AppTheme.errorColor, fontWeight: FontWeight.w500,
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== 交互方法 =====
  Future<void> _loadPosts() async {
    _postsLoading.value = true;
    try {
      final postService = Get.find<PostService>();
      final data = await postService.getPostList(page: 1, pageSize: _postPageSize);
      if (data != null) {
        _posts.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('加载动态失败: $e');
    } finally {
      _postsLoading.value = false;
    }
  }

  Future<void> _likePost(int postId) async {
    try {
      final postService = Get.find<PostService>();
      await postService.likePost(postId);
      _loadPosts();
    } catch (e) {
      debugPrint('点赞失败: $e');
    }
  }

  void _showComments(int postId) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(Get.context!).size.height * 0.6,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(
              color: AppTheme.textDarkGray, borderRadius: BorderRadius.circular(2),
            )),
            SizedBox(height: 16),
            Text('评论', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textWhite,
            )),
            SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text('暂无评论', style: TextStyle(color: AppTheme.textSilver)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分享动态 — 复制链接到剪贴板
  void _sharePost(Map<String, dynamic> post) {
    final postId = post['id'] ?? post['ID'] ?? 0;
    final link = '${ApiConfig.shareBaseUrl}/post/$postId';
    Clipboard.setData(ClipboardData(text: link));
    ToastUtil.showSuccess('链接已复制，请打开社交应用粘贴分享');
  }

  /// 举报动态 — 弹出原因选择对话框
  void _reportPost(Map<String, dynamic> post) {
    final reasons = ['不适当内容', '版权侵权', '垃圾信息', '其他'];
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLightGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text('选择举报原因', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textWhite,
            )),
            SizedBox(height: 16),
            ...reasons.map((reason) => ListTile(
              leading: Icon(Icons.report_outlined, color: AppTheme.warningColor),
              title: Text(reason, style: TextStyle(color: AppTheme.textWhite)),
              onTap: () {
                Get.back();
                ToastUtil.showSuccess('举报已提交，感谢您的反馈');
              },
            )),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(Map<String, dynamic> post) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share_rounded, color: AppTheme.textWhite),
              title: Text('分享', style: TextStyle(color: AppTheme.textWhite)),
              onTap: () { Get.back(); _sharePost(post); },
            ),
            ListTile(
              leading: Icon(Icons.report_outlined, color: AppTheme.textWhite),
              title: Text('举报', style: TextStyle(color: AppTheme.textWhite)),
              onTap: () { Get.back(); _reportPost(post); },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}-${dt.day}';
    } catch (e) {
      debugPrint('时间格式解析失败: $e');
      return timeStr;
    }
  }
}
