import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/utils/http_util.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

class LyricOptimizePage extends StatefulWidget {
  const LyricOptimizePage({super.key});

  @override
  State<LyricOptimizePage> createState() => _LyricOptimizePageState();
}

class _LyricOptimizePageState extends State<LyricOptimizePage> {
  final TextEditingController _originalController = TextEditingController();
  final TextEditingController _optimizedController = TextEditingController();

  final RxBool _isLoading = false.obs;
  final RxBool _hasResult = false.obs;
  final RxString _selectedStyle = '流行'.obs;
  final List<String> _styles = ['流行', '说唱', '民谣', '摇滚', '电子', 'R&B', '国风'];

  @override
  void dispose() {
    _originalController.dispose();
    _optimizedController.dispose();
    super.dispose();
  }

  Future<void> _optimize() async {
    final text = _originalController.text.trim();
    if (text.isEmpty) {
      ToastUtil.warning('请输入要优化的歌词');
      return;
    }

    _isLoading.value = true;
    try {
      final response = await HttpUtil().post(
        '/ai/lyric/optimize',
        data: {'lyric': text, 'style': _selectedStyle.value},
      );
      if (response.data['code'] == 0) {
        _optimizedController.text = response.data['data']['optimized_lyric'] ?? '';
        _hasResult.value = true;
        ToastUtil.showSuccess('优化成功');
      } else {
        ToastUtil.showError(response.data['msg'] ?? '优化失败');
      }
    } catch (e) {
      ToastUtil.showError('优化失败，请重试');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: const Text('歌词优化', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
        )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.surface1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppTheme.textWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 风格选择
            _buildStyleSection(),
            const SizedBox(height: 16),
            // 输入区
            _buildInputSection(),
            const SizedBox(height: 16),
            // 优化按钮
            _buildOptimizeButton(),
            const SizedBox(height: 20),
            // 结果区
            Obx(() => _hasResult.value ? _buildResultSection() : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  // ===== 风格选择 =====
  Widget _buildStyleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 16, decoration: BoxDecoration(
                color: AppTheme.brandIndigo, borderRadius: BorderRadius.circular(2),
              )),
              const SizedBox(width: 8),
              const Text('目标风格', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textWhite,
              )),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _styles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final style = _styles[index];
                return Obx(() {
                  final selected = _selectedStyle.value == style;
                  return GestureDetector(
                    onTap: () => _selectedStyle.value = style,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.brandIndigo.withValues(alpha: 0.2) : AppTheme.surface2,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        border: Border.all(
                          color: selected ? AppTheme.brandIndigo.withValues(alpha: 0.5) : AppTheme.borderSubtle.withValues(alpha: 0.3),
                          width: selected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(style, style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? AppTheme.brandIndigo : AppTheme.textSilver,
                      )),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== 输入区 =====
  Widget _buildInputSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.brandIndigo.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLarge),
                topRight: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, size: 16, color: AppTheme.brandIndigo),
                SizedBox(width: 6),
                Text('原始歌词', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.brandIndigo,
                )),
              ],
            ),
          ),
          // 输入框
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _originalController,
              maxLines: 8,
              minLines: 5,
              style: const TextStyle(
                color: AppTheme.textWhite, fontSize: 15, height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: '粘贴或输入你想要优化的歌词...',
                hintStyle: TextStyle(color: AppTheme.textDarkGray.withValues(alpha: 0.5)),
                border: InputBorder.none,
                filled: true,
                fillColor: AppTheme.surface2.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // 字数统计
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Text('${_originalController.text.length} 字', style: const TextStyle(
                  fontSize: 12, color: AppTheme.textLightGray,
                )),
                const Spacer(),
                if (_originalController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () { _originalController.clear(); setState(() {}); },
                    child: const Text('清空', style: TextStyle(
                      fontSize: 12, color: AppTheme.textLightGray,
                    )),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== 优化按钮 =====
  Widget _buildOptimizeButton() {
    return Obx(() {
      final loading = _isLoading.value;
      return GestureDetector(
        onTap: loading ? null : _optimize,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 50,
          decoration: BoxDecoration(
            gradient: loading
                ? LinearGradient(colors: [AppTheme.brandIndigo.withValues(alpha: 0.5), AppTheme.brandPurple.withValues(alpha: 0.5)])
                : const LinearGradient(colors: [AppTheme.brandIndigo, AppTheme.brandPurple]),
            borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
            boxShadow: [BoxShadow(
              color: AppTheme.brandIndigo.withValues(alpha: loading ? 0.1 : 0.3),
              blurRadius: loading ? 8 : 16,
              offset: const Offset(0, 4),
            )],
          ),
          child: Center(
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(
                    color: AppTheme.textWhite, strokeWidth: 2.5))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_fix_high_rounded, size: 20, color: AppTheme.textWhite),
                      SizedBox(width: 8),
                      Text('AI 优化歌词', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textWhite,
                      )),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  // ===== 结果区 =====
  Widget _buildResultSection() {
    return FadeInWidget(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLarge),
                  topRight: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.successColor),
                  const SizedBox(width: 6),
                  Text('优化结果', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.successColor,
                  )),
                ],
              ),
            ),
            // 结果内容
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _optimizedController,
                maxLines: 10,
                minLines: 5,
                readOnly: true,
                style: const TextStyle(
                  color: AppTheme.textWhite, fontSize: 15, height: 1.6,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: true,
                  fillColor: AppTheme.surface2.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // 操作按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _optimizedController.text));
                        ToastUtil.showSuccess('已复制到剪贴板');
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSilver),
                            SizedBox(width: 6),
                            Text('复制', style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSilver,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(result: _optimizedController.text),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.brandIndigo, AppTheme.brandPurple]),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.music_note_rounded, size: 16, color: AppTheme.textWhite),
                            SizedBox(width: 6),
                            Text('去创作', style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textWhite,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
