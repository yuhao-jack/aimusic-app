import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/utils/api_config.dart';
import 'package:aimusic_app/utils/toast_util.dart';

class ShareUtil {
  // 分享歌曲
  static void shareSong(Map<String, dynamic> song) {
    final title = song['title'] ?? '未知歌曲';
    final singer = song['singer'] ?? song['artist'] ?? '未知歌手';
    
    _showShareBottomSheet(
      title: '分享《$title》',
      subtitle: '歌手：$singer',
      cover: song['cover'],
      shareType: 'song',
      data: song,
    );
  }

  // 分享歌单
  static void sharePlaylist(Map<String, dynamic> playlist) {
    final name = playlist['name'] ?? '未知歌单';
    final description = playlist['description'] ?? '';
    
    _showShareBottomSheet(
      title: '分享歌单《$name》',
      subtitle: description.isNotEmpty ? description : '来听听我的歌单吧',
      cover: playlist['cover'],
      shareType: 'playlist',
      data: playlist,
    );
  }

  // 分享动态/帖子
  static void sharePost(Map<String, dynamic> post) {
    final content = post['content'] ?? '来看看这个动态';
    
    _showShareBottomSheet(
      title: '分享动态',
      subtitle: content.length > 50 ? '${content.substring(0, 50)}...' : content,
      shareType: 'post',
      data: post,
    );
  }

  // 显示分享底部弹窗
  static void _showShareBottomSheet({
    required String title,
    required String subtitle,
    String? cover,
    required String shareType,
    required Map<String, dynamic> data,
  }) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== Header =====
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (cover != null && cover.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          cover,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 48,
                              height: 48,
                              color: AppTheme.midDark,
                              child: Icon(
                                Icons.music_note,
                                color: AppTheme.textDarkGray,
                              ),
                            );
                          },
                        ),
                      ),
                    if (cover != null && cover.isNotEmpty)
                      SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textLightGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.textLightGray,
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1, color: AppTheme.borderGray),
              
              // ===== Share Options =====
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 第一行：常用分享
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildShareOption(
                          icon: Icons.wechat,
                          label: '微信好友',
                          color: Color(0xFF07C160),
                          onTap: () => _handleShare('wechat_friend', shareType, data),
                        ),
                        _buildShareOption(
                          icon: Icons.wechat_outlined,
                          label: '朋友圈',
                          color: Color(0xFF07C160),
                          onTap: () => _handleShare('wechat_moments', shareType, data),
                        ),
                        _buildShareOption(
                          icon: Icons.chat_outlined,
                          label: 'QQ好友',
                          color: Color(0xFF12B7F5),
                          onTap: () => _handleShare('qq_friend', shareType, data),
                        ),
                        _buildShareOption(
                          icon: Icons.campaign_outlined,
                          label: '微博',
                          color: Color(0xFFFF8200),
                          onTap: () => _handleShare('weibo', shareType, data),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // 第二行：更多选项
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildShareOption(
                          icon: Icons.link,
                          label: '复制链接',
                          color: AppTheme.textSilver,
                          onTap: () => _handleShare('copy_link', shareType, data),
                        ),
                        _buildShareOption(
                          icon: Icons.download_outlined,
                          label: '保存图片',
                          color: AppTheme.textSilver,
                          onTap: () => _handleShare('save_image', shareType, data),
                        ),
                        _buildShareOption(
                          icon: Icons.share_outlined,
                          label: '更多',
                          color: AppTheme.textSilver,
                          onTap: () => _handleShare('more', shareType, data),
                        ),
                        SizedBox(width: 60), // 占位
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // 构建分享选项
  static Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSilver,
            ),
          ),
        ],
      ),
    );
  }

  // 处理分享
  static void _handleShare(String platform, String shareType, Map<String, dynamic> data) {
    Get.back(); // 关闭底部弹窗
    
    // 生成分享链接
    final String link = _generateShareLink(shareType, data);
    
    switch (platform) {
      case 'copy_link':
        // 复制链接
        _copyLink(link);
        break;
      case 'save_image':
        // 保存图片
        ToastUtil.showSuccess('图片已保存');
        break;
      case 'wechat_friend':
        // 微信好友 - 复制链接
        _copyLink(link);
        ToastUtil.showSuccess('链接已复制，请打开微信粘贴分享');
        break;
      case 'wechat_moments':
        // 朋友圈 - 复制链接
        _copyLink(link);
        ToastUtil.showSuccess('链接已复制，请打开朋友圈粘贴分享');
        break;
      case 'qq_friend':
        // QQ好友 - 复制链接
        _copyLink(link);
        ToastUtil.showSuccess('链接已复制，请打开QQ粘贴分享');
        break;
      case 'weibo':
        // 微博 - 复制链接
        _copyLink(link);
        ToastUtil.showSuccess('链接已复制，请打开微博粘贴分享');
        break;
      case 'more':
        // 更多分享 - 复制链接
        _copyLink(link);
        break;
      default:
        _copyLink(link);
    }
  }

  // 生成分享链接
  static String _generateShareLink(String shareType, Map<String, dynamic> data) {
    final base = ApiConfig.shareBaseUrl;
    switch (shareType) {
      case 'song':
        final songId = data['id'] ?? '';
        return '$base/song/$songId';
      case 'playlist':
        final playlistId = data['id'] ?? '';
        return '$base/playlist/$playlistId';
      case 'post':
        final postId = data['id'] ?? '';
        return '$base/post/$postId';
      default:
        return base;
    }
  }

  // 复制链接到剪贴板
  static void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ToastUtil.showSuccess('链接已复制');
  }
}
