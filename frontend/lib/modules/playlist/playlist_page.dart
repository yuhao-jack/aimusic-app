import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/utils/http_util.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'playlist_controller.dart';

class PlaylistPage extends GetView<PlaylistController> {
  PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textWhite),
          onPressed: () => Get.back(),
        ),
        title: Text(
          '我的歌单',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: AppTheme.brandIndigo,
        backgroundColor: AppTheme.surface2,
        onRefresh: () => controller.fetchPlaylists(),
        child: Obx(
          () => controller.isLoading.value
              ? Center(child: CircularProgressIndicator())
              : controller.playlistList.isEmpty
                  ? ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [_buildEmptyState()],
                    )
                  : ListView.builder(
                      physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      itemCount: controller.playlistList.length,
                      itemBuilder: (context, index) {
                        final playlist = controller.playlistList[index];
                        return _buildPlaylistCard(playlist);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_play_outlined,
            size: 100,
            color: AppTheme.textDarkGray,
          ),
          SizedBox(height: 24),
          Text(
            '还没有歌单',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.textMediumGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '创建你的第一个歌单吧~',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textDarkGray,
            ),
          ),
          SizedBox(height: 32),
          SizedBox(
            width: 180,
            child: ElevatedButton.icon(
              onPressed: () => _showCreatePlaylistDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.textWhite,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: Icon(Icons.add, size: 20),
              label: Text(
                '创建歌单',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
    final isPublic = playlist['is_public'] ?? false;
    final coverColor = isPublic ? AppTheme.primaryColor : AppTheme.brandPurple;

    return GestureDetector(
      onTap: () {
        // 跳转到歌单详情页
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // 封面
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [coverColor, coverColor.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.music_note,
                size: 36,
                color: AppTheme.textWhite,
              ),
            ),
            SizedBox(width: 16),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          playlist['name'] ?? '未命名歌单',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPublic)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '公开',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '${playlist['song_count'] ?? 0} 首歌曲',
                    style: TextStyle(
                      color: AppTheme.textLightGray,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      // 点赞按钮
                      GestureDetector(
                        onTap: () => _likePlaylist(playlist['id']),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 16,
                              color: AppTheme.textLightGray,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${playlist['like_count'] ?? 0}',
                              style: TextStyle(
                                color: AppTheme.textLightGray,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        '创建于 ${playlist['created_at']?.toString().substring(0, 10) ?? ''}',
                        style: TextStyle(
                          color: AppTheme.textDarkGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 更多操作
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: AppTheme.textLightGray,
              ),
              color: AppTheme.surface3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'like') {
                  controller.likePlaylist(playlist['id']);
                } else if (value == 'delete') {
                  _showDeleteDialog(playlist['id']);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'like',
                  child: ListTile(
                    leading: Icon(Icons.favorite_border, color: AppTheme.brandIndigo),
                    title: Text(
                      '点赞',
                      style: TextStyle(color: AppTheme.textWhite),
                    ),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                    title: Text(
                      '删除歌单',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 歌单点赞
  void _likePlaylist(int playlistId) async {
    try {
      final response = await HttpUtil().post('/playlist/$playlistId/like');
      if (response.data['code'] == 0) {
        ToastUtil.showSuccess('已点赞');
        controller.fetchPlaylists();
      } else {
        ToastUtil.showError(response.data['msg'] ?? '点赞失败');
      }
    } catch (e) {
      ToastUtil.showError('网络错误');
    }
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();
    // 重置公开状态
    controller.isPublicPlaylist.value = false;

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '创建新歌单',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: '请输入歌单名称',
                  hintStyle: TextStyle(color: AppTheme.textDarkGray),
                  filled: true,
                  fillColor: AppTheme.surface3,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Obx(
                () => SwitchListTile(
                  value: controller.isPublicPlaylist.value,
                  onChanged: (value) => controller.isPublicPlaylist.value = value,
                  title: Text(
                    '公开歌单',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '公开后其他用户可以看到并收藏',
                    style: TextStyle(
                      color: AppTheme.textLightGray,
                      fontSize: 12,
                    ),
                  ),
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: AppTheme.textLightGray,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          controller.createPlaylist(
                            nameController.text.trim(),
                            isPublic: controller.isPublicPlaylist.value,
                          );
                          Get.back();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.textWhite,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        '创建',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  void _showDeleteDialog(int playlistId) {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                size: 56,
                color: AppTheme.errorColor,
              ),
              SizedBox(height: 16),
              Text(
                '确定删除歌单？',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '删除后无法恢复，歌单内的歌曲也会移除',
                style: TextStyle(
                  color: AppTheme.textLightGray,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        '取消',
                        style: TextStyle(color: AppTheme.textLightGray),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.deletePlaylist(playlistId);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: AppTheme.textWhite,
                      ),
                      child: Text('删除'),
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
}
