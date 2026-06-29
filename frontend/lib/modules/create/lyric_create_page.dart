import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/create/lyric_create_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

// =============================================================================
// LyricCreatePage — 真正的 AI 创作工具体验，而不是表单
// =============================================================================

class LyricCreatePage extends GetView<LyricCreateController> {
  const LyricCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: const Text(
          'AI 歌词创作',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppTheme.surface1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textWhite, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isGenerating.value) {
          return _buildGeneratingState();
        }
        if (controller.showResult.value) {
          return _buildResultState();
        }
        return _buildInputForm();
      }),
    );
  }

  // ===========================================================================
  // INPUT FORM — 玻璃质感面板 + pill chip + 渐变辉光按钮
  // ===========================================================================

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // --------------- 关键词输入 ---------------
          _buildSectionHeader(icon: Icons.tips_and_updates_rounded, label: '创作灵感', step: '01'),
          const SizedBox(height: 14),
          FadeInWidget(
            delayMs: 40,
            child: _buildGlassInput(),
          ),
          const SizedBox(height: 32),

          // --------------- 情绪 ---------------
          _buildSectionHeader(icon: Icons.auto_awesome_rounded, label: '情绪基调', step: '02'),
          const SizedBox(height: 14),
          FadeInWidget(
            delayMs: 80,
            child: Obx(() => _buildPillChips(
                  options: controller.emotionOptions,
                  selected: controller.selectedMood.value,
                  onSelected: (v) => controller.selectedMood.value = v,
                )),
          ),
          const SizedBox(height: 32),

          // --------------- 风格 ---------------
          _buildSectionHeader(icon: Icons.queue_music_rounded, label: '音乐风格', step: '03'),
          const SizedBox(height: 14),
          FadeInWidget(
            delayMs: 130,
            child: Obx(() => _buildPillChips(
                  options: controller.styleOptions,
                  selected: controller.selectedGenre.value,
                  onSelected: (v) => controller.selectedGenre.value = v,
                )),
          ),
          const SizedBox(height: 32),

          // --------------- 语言 ---------------
          _buildSectionHeader(icon: Icons.translate_rounded, label: '创作语言', step: '04'),
          const SizedBox(height: 14),
          FadeInWidget(
            delayMs: 180,
            child: _buildLanguageSelector(),
          ),
          const SizedBox(height: 40),

          // --------------- 生成按钮 ---------------
          FadeInWidget(
            delayMs: 230,
            child: _buildGenerateButton(),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADER — step 编号 + 图标 + 标签 + 装饰线
  // ===========================================================================

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    required String step,
  }) {
    return Row(
      children: [
        // Step badge
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryToSecondary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textWhite,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: AppTheme.textSilver),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        // Decorative line
        Container(
          height: 1,
          width: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.5),
                AppTheme.primaryColor.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // GLASS INPUT — 毛玻璃面板 + 主色辉光下边框
  // ===========================================================================

  Widget _buildGlassInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
        border: Border.all(
          color: AppTheme.borderSubtle.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller.promptController,
        maxLines: 5,
        minLines: 3,
        style: const TextStyle(
          color: AppTheme.textWhite,
          fontSize: 15,
          height: 1.6,
        ),
        cursorColor: AppTheme.primaryColor,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.surfaceElevated.withValues(alpha: 0.5),
          hintText: '描述你想创作的歌曲主题…\n例如：夏夜的星空下，初恋的怦然心动',
          hintStyle: const TextStyle(
            color: AppTheme.textDim,
            fontSize: 14,
            height: 1.6,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        ),
      ),
    );
  }

  // ===========================================================================
  // PILL CHIPS — 渐变填充 + 光泽扫光效果
  // ===========================================================================

  Widget _buildPillChips({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    // 横向滑动选择，避免纵向排列占用过多空间
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selected == option;
          return _PillChip(
            label: option,
            isSelected: isSelected,
            onTap: () => onSelected(option),
          );
        },
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return _LanguageSelector(
      languages: const ['中文', 'English', '日本語', '한국어'],
      selected: controller.selectedLanguage.value,
      onChanged: (v) => controller.selectedLanguage.value = v,
    );
  }

  Widget _buildGenerateButton() {
    return _GlowGenerateButton(
      onTap: () {
        // 防重复提交：正在生成中则忽略点击
        if (controller.isGenerating.value) return;
        controller.generateLyric();
      },
    );
  }

  Widget _buildGeneratingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInWidget(
            child: _ProgressMeter(),
          ),
          const SizedBox(height: 32),
          ElasticButton(
            onTap: () => controller.cancelGeneration(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.borderSubtle.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                color: AppTheme.surface3.withValues(alpha: 0.5),
              ),
              child: const Text(
                '取消创作',
                style: TextStyle(
                  color: AppTheme.textSilver,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --------------- Header ---------------
          FadeInWidget(
            child: Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, size: 18, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  '创作完成',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FadeInWidget(
            delayMs: 30,
            child: const Text(
              '你的专属歌词已经生成',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textDim,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --------------- Lyrics Glass Panel ---------------
          FadeInWidget(
            delayMs: 60,
            child: _buildLyricsCard(),
          ),
          const SizedBox(height: 24),

          // --------------- Action Buttons (Row 1) ---------------
          FadeInWidget(
            delayMs: 100,
            child: Row(
              children: [
                Expanded(
                  child: _GlassActionButton(
                    icon: Icons.copy_rounded,
                    label: '复制',
                    onTap: () => controller.copyLyric(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GlassActionButton(
                    icon: Icons.edit_rounded,
                    label: '编辑',
                    onTap: () => controller.editLyric(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --------------- Action Buttons (Row 2) ---------------
          FadeInWidget(
            delayMs: 140,
            child: Row(
              children: [
                Expanded(
                  child: _GlassActionButton(
                    icon: Icons.refresh_rounded,
                    label: '重新创作',
                    onTap: () => controller.regenerateLyric(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElasticButton(
                    onTap: () => Get.toNamed(AppRoutes.createSong),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryToSecondary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.music_note_rounded,
                              size: 18, color: AppTheme.textWhite),
                          SizedBox(width: 6),
                          Text(
                            '用于歌曲',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textWhite,
                              letterSpacing: 0.5,
                            ),
                          ),
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
    );
  }

  // ===========================================================================
  // LYRICS CARD — 全玻璃面板 + 滚动歌词
  // ===========================================================================


  Widget _buildLyricsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(
              color: AppTheme.borderSubtle.withValues(alpha: 0.35),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxHeight: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top gradient accent bar
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryToSecondary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusXLarge),
                    topRight: Radius.circular(AppTheme.radiusXLarge),
                  ),
                ),
              ),
              // Lyrics content — scrollable
              Flexible(
                child: Obx(() {
                  final lyric = controller.generatedLyric.value;
                  final lines = lyric.split('\n');
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(lines.length, (i) {
                        final line = lines[i];
                        final isEmpty = line.trim().isEmpty;
                        // Detect section headers like [Verse], [Chorus]
                        final isSectionHeader =
                            line.trim().startsWith('[') && line.trim().endsWith(']');

                        return Padding(
                          padding: EdgeInsets.only(
                            top: isEmpty ? 12 : 4,
                            bottom: 2,
                          ),
                          child: isSectionHeader
                              ? Text(
                                  line.trim(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor.withValues(alpha: 0.8),
                                    letterSpacing: 1.2,
                                  ),
                                )
                              : Text(
                                  line,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isEmpty
                                        ? FontWeight.w400
                                        : FontWeight.w500,
                                    color: isEmpty
                                        ? Colors.transparent
                                        : AppTheme.textWhite,
                                    height: 1.7,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        );
                      }),
                    ),
                  );
                }),
              ),
              // Bottom fade gradient
              Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.surfaceElevated.withValues(alpha: 0),
                      AppTheme.surfaceElevated.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppTheme.radiusXLarge),
                    bottomRight: Radius.circular(AppTheme.radiusXLarge),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}

// =============================================================================
// _PillChip — 手写 pill button，选中时渐变填充 + 光泽扫光
// =============================================================================

class _PillChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PillChip> createState() => _PillChipState();
}

class _PillChipState extends State<_PillChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOutSine),
    );

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );

    if (widget.isSelected) {
      _shimmerCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(_PillChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _shimmerCtrl.repeat();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _shimmerCtrl.stop();
      _shimmerCtrl.reset();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: GestureDetector(
            onTapDown: (_) => _scaleCtrl.forward(),
            onTapUp: (_) {
              _scaleCtrl.reverse();
              widget.onTap();
            },
            onTapCancel: () => _scaleCtrl.reverse(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                color: widget.isSelected ? null : AppTheme.surface3.withValues(alpha: 0.6),
                gradient: widget.isSelected
                    ? AppTheme.primaryToSecondary
                    : null,
                border: Border.all(
                  color: widget.isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppTheme.borderSubtle.withValues(alpha: 0.4),
                  width: widget.isSelected ? 0.8 : 0.5,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 0),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                child: Stack(
                  children: [
                    // Label text
                    Center(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: widget.isSelected
                              ? AppTheme.textWhite
                              : AppTheme.textSilver,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Shimmer sweep overlay
                    if (widget.isSelected)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _shimmerAnim,
                          builder: (context, _) {
                            return _buildShimmerOverlay();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerOverlay() {
    return FractionallySizedBox(
      widthFactor: 0.4,
      alignment: Alignment(_shimmerAnim.value, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// LANGUAGE SELECTOR — 玻璃胶囊选择器
// =============================================================================

class _LanguageSelector extends StatelessWidget {
  final List<String> languages;
  final String selected;
  final ValueChanged<String> onChanged;

  const _LanguageSelector({
    required this.languages,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface3.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
        border: Border.all(
          color: AppTheme.borderSubtle.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: languages.map((lang) {
          final isSelected = lang == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(lang),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  lang,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.textWhite : AppTheme.textSilver,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


// =============================================================================
// GENERATE BUTTON — 渐变 pill + 辉光投影 + 呼吸光效
// =============================================================================


class _GlowGenerateButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GlowGenerateButton({required this.onTap});

  @override
  State<_GlowGenerateButton> createState() => _GlowGenerateButtonState();
}

class _GlowGenerateButtonState extends State<_GlowGenerateButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _scaleAnim]),
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25 * _pulseAnim.value),
                  blurRadius: 20 * _pulseAnim.value,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1 * _pulseAnim.value),
                  blurRadius: 40 * _pulseAnim.value,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _scaleCtrl.forward().then((_) => _scaleCtrl.reverse());
                    widget.onTap();
                  },
                  splashColor: Colors.white.withValues(alpha: 0.1),
                  highlightColor: Colors.white.withValues(alpha: 0.05),
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryToSecondary,
                      borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusFullPill)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 20,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '开始创作',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textWhite,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// GENERATING STATE — 四段进度仪表 + 脉冲动画
// ===========================================================================

final List<_ProgressStep> _generationSteps = [
  _ProgressStep(label: '分析关键词', icon: Icons.search_rounded),
  _ProgressStep(label: '构建韵律结构', icon: Icons.auto_awesome_rounded),
  _ProgressStep(label: '匹配旋律线条', icon: Icons.music_note_rounded),
  _ProgressStep(label: '生成完整歌词', icon: Icons.lyrics_rounded),
];

class _ProgressStep {
  final String label;
  final IconData icon;
  const _ProgressStep({required this.label, required this.icon});
}


class _ProgressMeter extends StatefulWidget {
  @override
  State<_ProgressMeter> createState() => _ProgressMeterState();
}

class _ProgressMeterState extends State<_ProgressMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // Simulate progress based on controller.progressText
  int _getCompletedCount(String progress) {
    if (progress.contains('韵律') || progress.contains('结构')) return 1;
    if (progress.contains('旋律') || progress.contains('匹配')) return 2;
    if (progress.contains('完整') || progress.contains('歌词')) return 3;
    if (progress.contains('完成') || progress.contains('成功')) return 4;
    return 0;
  }

  int _getActiveIndex(String progress) {
    final c = _getCompletedCount(progress);
    return c < 4 ? c : -1;
  }

  LyricCreateController get _ctrl => Get.find<LyricCreateController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final progress = _ctrl.progressText.value;
      final completed = _getCompletedCount(progress);
      final activeIdx = _getActiveIndex(progress);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(
            color: AppTheme.borderSubtle.withValues(alpha: 0.4),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.surfaceElevated.withValues(alpha: 0.35),
                    AppTheme.surface3.withValues(alpha: 0.25),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Text(
                    'AI 正在创作',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textWhite,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '创意引擎全力运转中…',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDim,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Progress steps
                  ...List.generate(_generationSteps.length, (i) {
                    final step = _generationSteps[i];
                    final isCompleted = i < completed;
                    final isActive = i == activeIdx;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          // Icon / number badge
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (context, _) {
                              return Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? AppTheme.successColor
                                      : isActive
                                          ? AppTheme.primaryColor
                                          : AppTheme.surface2.withValues(alpha: 0.6),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.4 * _pulseAnim.value),
                                            blurRadius: 12 * _pulseAnim.value,
                                            offset: const Offset(0, 0),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded,
                                        size: 20, color: AppTheme.textWhite)
                                    : isActive
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.textWhite,
                                            ),
                                          )
                                        : Icon(
                                            step.icon,
                                            size: 18,
                                            color: AppTheme.textDim,
                                          ),
                              );
                            },
                          ),
                          const SizedBox(width: 14),
                          // Label
                          Text(
                            step.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isCompleted || isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isCompleted
                                  ? AppTheme.successColor
                                  : isActive
                                      ? AppTheme.textWhite
                                      : AppTheme.textDim,
                            ),
                          ),
                          const Spacer(),
                          // Connector line
                          if (i < _generationSteps.length - 1)
                            Container(
                              width: 1,
                              height: 20,
                              color: isCompleted
                                  ? AppTheme.successColor.withValues(alpha: 0.3)
                                  : AppTheme.borderSubtle.withValues(alpha: 0.15),
                            ),
                        ],
                      ),
                    );
                  }),

                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ===========================================================================
// GLASS ACTION BUTTON — 玻璃质感弹框按钮
// ===========================================================================

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElasticButton(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: AppTheme.glassDecoration(
          radius: AppTheme.radiusLarge,
          tint: AppTheme.surfaceElevated,
          opacity: 0.5,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.textSilver),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSilver,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
