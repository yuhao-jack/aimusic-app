import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/utils/http_util.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

/// 音乐日记控制器
class MusicDiaryController extends GetxController {
  final RxList<dynamic> diaries = <dynamic>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDiaries();
  }

  /// 加载日记列表
  Future<void> loadDiaries() async {
    isLoading.value = true;
    try {
      final response = await HttpUtil().get('/diary/list');
      if (response.data['code'] == 0) {
        diaries.value = response.data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('加载日记失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 发布日记
  Future<bool> publishDiary({
    required String content,
    required String mood,
    int? songId,
    bool isPublic = true,
  }) async {
    isSubmitting.value = true;
    try {
      final response = await HttpUtil().post('/diary/create', data: {
        'content': content,
        'mood': mood,
        'song_id': songId,
        'is_public': isPublic,
      });
      if (response.data['code'] == 0) {
        await loadDiaries();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('发布日记失败: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 删除日记
  Future<void> deleteDiary(int diaryId) async {
    try {
      final response = await HttpUtil().delete('/diary/$diaryId');
      if (response.data['code'] == 0) {
        diaries.removeWhere((d) => d['id'] == diaryId);
      }
    } catch (e) {
      debugPrint('删除日记失败: $e');
    }
  }
}

/// 心情标签数据
class MoodTag {
  final String emoji;
  final String label;
  final Color color;

  const MoodTag({
    required this.emoji,
    required this.label,
    required this.color,
  });
}

/// 预设心情标签列表
const List<MoodTag> moodTags = [
  MoodTag(emoji: '😊', label: '开心', color: Color(0xFFFFD700)),
  MoodTag(emoji: '😢', label: '伤感', color: Color(0xFF6495ED)),
  MoodTag(emoji: '😌', label: '平静', color: Color(0xFF90EE90)),
  MoodTag(emoji: '🥰', label: '甜蜜', color: Color(0xFFFF69B4)),
  MoodTag(emoji: '😤', label: '愤怒', color: Color(0xFFFF4500)),
  MoodTag(emoji: '🥺', label: '思念', color: Color(0xFFDDA0DD)),
  MoodTag(emoji: '🎉', label: '兴奋', color: Color(0xFFFFA500)),
  MoodTag(emoji: '🌙', label: '深夜', color: Color(0xFF4169E1)),
];

/// 音乐日记页面
class MusicDiaryPage extends StatefulWidget {
  const MusicDiaryPage({super.key});

  @override
  State<MusicDiaryPage> createState() => _MusicDiaryPageState();
}

class _MusicDiaryPageState extends State<MusicDiaryPage> {
  final MusicDiaryController _controller = Get.put(MusicDiaryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: const Text(
          '音乐日记',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return _buildLoadingState();
        }
        if (_controller.diaries.isEmpty) {
          return _buildEmptyState();
        }
        return _buildDiaryList();
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPublishSheet(),
        backgroundColor: AppTheme.brandIndigo,
        child: const Icon(Icons.edit_rounded, color: AppTheme.textWhite),
      ),
    );
  }

  /// 加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.brandIndigo,
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: FadeInWidget(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_rounded,
              size: 64,
              color: AppTheme.textDarkGray.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有音乐日记',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSilver,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '记录此刻的心情和音乐',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 日记列表
  Widget _buildDiaryList() {
    return RefreshIndicator(
      color: AppTheme.brandIndigo,
      backgroundColor: AppTheme.surface2,
      onRefresh: _controller.loadDiaries,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _controller.diaries.length,
        itemBuilder: (context, index) {
          return FadeInWidget(
            delayMs: index * 50,
            child: _buildDiaryCard(_controller.diaries[index]),
          );
        },
      ),
    );
  }

  /// 日记卡片
  Widget _buildDiaryCard(Map diary) {
    final mood = moodTags.firstWhere(
      (m) => m.label == diary['mood'],
      orElse: () => moodTags[0],
    );
    final song = diary['song'];
    final isPublic = diary['is_public'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface3,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(
          color: AppTheme.borderSubtle.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：心情标签 + 时间 + 公开/私密标识
            Row(
              children: [
                // 心情标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: mood.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    border: Border.all(
                      color: mood.color.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mood.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: mood.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 公开/私密标识
                Icon(
                  isPublic ? Icons.public_rounded : Icons.lock_rounded,
                  size: 14,
                  color: AppTheme.textLightGray,
                ),
                const SizedBox(width: 8),
                // 时间
                Text(
                  _formatTime(diary['created_at']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 日记文字内容
            Text(
              diary['content'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textWhite,
                height: 1.6,
              ),
            ),
            // 关联歌曲
            if (song != null) ...[
              const SizedBox(height: 12),
              _buildSongCard(song),
            ],
          ],
        ),
      ),
    );
  }

  /// 关联歌曲卡片
  Widget _buildSongCard(Map song) {
    return Container(
      padding: const EdgeInsets.all(10),
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
          // 歌曲封面
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: song['cover_url'] != null
                ? CachedNetworkImage(
                    imageUrl: song['cover_url'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _buildSongPlaceholder(),
                  )
                : _buildSongPlaceholder(),
          ),
          const SizedBox(width: 10),
          // 歌曲信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song['title'] ?? '未知歌曲',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song['artist_name'] ?? '未知歌手',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSilver,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 播放按钮
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.brandIndigo.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 18,
              color: AppTheme.brandIndigo,
            ),
          ),
        ],
      ),
    );
  }

  /// 歌曲占位图
  Widget _buildSongPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surface3,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        size: 20,
        color: AppTheme.textDarkGray,
      ),
    );
  }

  /// 格式化时间
  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inDays > 365) {
        return '${(diff.inDays / 365).floor()}年前';
      } else if (diff.inDays > 30) {
        return '${(diff.inDays / 30).floor()}个月前';
      } else if (diff.inDays > 0) {
        return '${diff.inDays}天前';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}小时前';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return '';
    }
  }

  /// 显示发布日记底部面板
  void _showPublishSheet() {
    final contentController = TextEditingController();
    String selectedMood = moodTags[0].label;
    bool isPublic = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusExtraLarge),
              ),
            ),
            child: Column(
              children: [
                // 顶部拖拽条
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textDarkGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // 标题
                const Text(
                  '写音乐日记',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 20),
                // 心情选择
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '选择心情',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSilver,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: moodTags.map((mood) {
                          final isSelected = selectedMood == mood.label;
                          return GestureDetector(
                            onTap: () {
                              setState(() => selectedMood = mood.label);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? mood.color.withOpacity(0.2)
                                    : AppTheme.surface2,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFullPill,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? mood.color.withOpacity(0.5)
                                      : AppTheme.borderSubtle,
                                  width: isSelected ? 1.5 : 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    mood.emoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mood.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? mood.color
                                          : AppTheme.textSilver,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 文字输入
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                        border: Border.all(
                          color: AppTheme.borderSubtle.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textWhite,
                        ),
                        decoration: InputDecoration(
                          hintText: '写下此刻的心情...\n\n正在听什么歌？有什么感想？',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textLightGray.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 底部操作栏
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // 公开/私密切换
                      GestureDetector(
                        onTap: () {
                          setState(() => isPublic = !isPublic);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surface2,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFullPill,
                            ),
                            border: Border.all(
                              color: AppTheme.borderSubtle.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPublic
                                    ? Icons.public_rounded
                                    : Icons.lock_rounded,
                                size: 16,
                                color: isPublic
                                    ? AppTheme.brandIndigo
                                    : AppTheme.textSilver,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isPublic ? '公开' : '私密',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isPublic
                                      ? AppTheme.brandIndigo
                                      : AppTheme.textSilver,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // 发布按钮
                      ElevatedButton(
                        onPressed: () async {
                          if (contentController.text.trim().isEmpty) {
                            ToastUtil.error('请输入日记内容');
                            return;
                          }
                          final success = await _controller.publishDiary(
                            content: contentController.text.trim(),
                            mood: selectedMood,
                            isPublic: isPublic,
                          );
                          if (success) {
                            Get.back();
                            ToastUtil.success('发布成功');
                          } else {
                            ToastUtil.error('发布失败');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandIndigo,
                          foregroundColor: AppTheme.textWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFullPill,
                            ),
                          ),
                        ),
                        child: const Text(
                          '发布',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
