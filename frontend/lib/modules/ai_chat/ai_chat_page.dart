import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/ai_chat/ai_chat_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

/// AI对话推荐页面
/// 聊天界面：用户消息右侧，AI回复左侧，支持推荐歌曲点击播放
class AiChatPage extends GetView<AiChatController> {
  AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryToSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppTheme.textWhite),
            ),
            SizedBox(width: 8),
            Text(
              'AI 音乐助手',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textWhite),
        ),
        actions: [
          IconButton(
            onPressed: () => _showClearDialog(),
            icon: Icon(Icons.delete_outline_rounded,
                color: AppTheme.textSilver, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          // 聊天消息列表
          Expanded(child: _buildMessageList()),
          // 快捷问题
          _buildQuickQuestions(),
          // 输入框
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return _buildEmptyView();
      }
      return ListView.builder(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: controller.messages.length +
            (controller.isLoading.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.messages.length) {
            return _buildTypingIndicator();
          }
          final msg = controller.messages[index];
          final isUser = msg['role'] == 'user';
          return isUser
              ? _buildUserMessage(msg['content'])
              : _buildAiMessage(msg);
        },
      );
    });
  }

  Widget _buildEmptyView() {
    return Center(
      child: FadeInWidget(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryToSecondary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandIndigo.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 30, color: AppTheme.textWhite),
            ),
            SizedBox(height: 20),
            Text(
              '有什么想听的？',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '告诉我你的心情或场景\n我来为你推荐音乐',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSilver,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessage(String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.brandIndigo.withOpacity(0.2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: AppTheme.brandIndigo.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textWhite,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(Map<String, dynamic> msg) {
    final content = msg['content'] as String? ?? '';
    final songs = (msg['songs'] as List?) ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryToSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                size: 16, color: AppTheme.textWhite),
          ),
          SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface3,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: AppTheme.borderSubtle.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textWhite,
                      height: 1.4,
                    ),
                  ),
                ),
                // 推荐歌曲列表
                if (songs.isNotEmpty) ...[
                  SizedBox(height: 8),
                  ...songs.map((song) => _buildSongCard(song)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongCard(Map<String, dynamic> song) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: ElasticButton(
        onTap: () {
          // 跳转到播放器
          Get.toNamed(AppRoutes.player, arguments: {
            'id': song['id'],
            'title': song['title'] ?? '未知歌曲',
            'artist': song['artist'] ?? '未知歌手',
            'cover': song['cover_url'] ?? song['cover'] ?? '',
            'audio_url': song['audio_url'] ?? '',
          });
        },
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.borderSubtle.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // 播放图标
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.brandIndigo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.play_arrow_rounded,
                    size: 20, color: AppTheme.brandIndigo),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song['title'] ?? '未知歌曲',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      song['artist'] ?? '未知歌手',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSilver,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppTheme.textDarkGray),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryToSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                size: 16, color: AppTheme.textWhite),
          ),
          SizedBox(width: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: AppTheme.borderSubtle.withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4),
                _buildDot(1),
                SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppTheme.textSilver.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  /// 快捷问题
  Widget _buildQuickQuestions() {
    return Obx(() {
      if (controller.messages.isNotEmpty) return SizedBox.shrink();
      return SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.quickQuestions.length,
          itemBuilder: (context, index) {
            final question = controller.quickQuestions[index];
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => controller.sendMessage(question),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface3,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    border: Border.all(
                      color: AppTheme.brandIndigo.withOpacity(0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.brandIndigo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  /// 输入框
  Widget _buildInputBar() {
    final textController = TextEditingController();

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(Get.context!).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderSubtle.withOpacity(0.4),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                border: Border.all(
                  color: AppTheme.borderSubtle.withOpacity(0.4),
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: textController,
                style: TextStyle(color: AppTheme.textWhite, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '帮我找一首适合下雨天听的歌',
                  hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    controller.sendMessage(value);
                    textController.clear();
                  }
                },
              ),
            ),
          ),
          SizedBox(width: 8),
          Obx(() => GestureDetector(
                onTap: controller.isLoading.value
                    ? null
                    : () {
                        final text = textController.text;
                        if (text.trim().isNotEmpty) {
                          controller.sendMessage(text);
                          textController.clear();
                        }
                      },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: controller.isLoading.value
                        ? null
                        : AppTheme.primaryToSecondary,
                    color: controller.isLoading.value
                        ? AppTheme.surface3
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: 20,
                    color: controller.isLoading.value
                        ? AppTheme.textDarkGray
                        : AppTheme.textWhite,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: Get.context!,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '清空聊天记录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '确定要清空所有聊天记录吗？',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSilver,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textWhite,
                        side: BorderSide(color: AppTheme.borderGray),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                      ),
                      child: Text('取消'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.clearMessages();
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: AppTheme.textWhite,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                      ),
                      child: Text('清空'),
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
