import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/create/song_create_controller.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/widgets/animated_transitions.dart';

class SongCreatePage extends GetView<SongCreateController> {
  SongCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Text(
          '生成歌曲',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppTheme.surface1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textWhite),
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

  // =================================================================
  // INPUT FORM  —  3 glass panels
  // =================================================================
  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- Block 1: 歌词 (glass panel) ----------
          FadeInWidget(
            child: ClipRRect(
              borderRadius: AppTheme.radiusXLargeAll,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: AppTheme.fullGlassEffect(),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Corner badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '🎵 歌词',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textWhite,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: controller.lyricController,
                        maxLines: 8,
                        minLines: 6,
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceElevated,
                          hintText: '在此处粘贴你的歌词...',
                          hintStyle: TextStyle(
                            color: AppTheme.textLightGray,
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppTheme.radiusComfortableAll,
                            borderSide: BorderSide(
                              color: AppTheme.borderSubtle.withValues(alpha: 0.4),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppTheme.radiusComfortableAll,
                            borderSide: BorderSide(
                              color: AppTheme.borderSubtle.withValues(alpha: 0.4),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppTheme.radiusComfortableAll,
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),

          // ---------- Block 2: 风格 + 节奏 (single glass panel) ----------
          FadeInWidget(
            delayMs: 60,
            child: ClipRRect(
              borderRadius: AppTheme.radiusXLargeAll,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: AppTheme.fullGlassEffect(),
                  padding: EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Genre pills
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                                border: Border.all(
                                  color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '🎶 风格',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textWhite,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Obx(() => _buildGenrePills()),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Right: Tempo slider
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '🥁 节奏',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textWhite,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Obx(() => _buildCompactTempoSlider()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),

          // ---------- Block 3: 人声设置 (expandable glass panel) ----------
          FadeInWidget(
            delayMs: 120,
            child: ClipRRect(
              borderRadius: AppTheme.radiusXLargeAll,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Obx(() {
                  final expanded = controller.vocalsEnabled.value;
                  return Container(
                    decoration: AppTheme.fullGlassEffect(),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row — always visible
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.pinkAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                                border: Border.all(
                                  color: AppTheme.pinkAccent.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '🗣️ 人声',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textWhite,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Spacer(),
                            GestureDetector(
                              onTap: () => controller.vocalsEnabled.value = !expanded,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    expanded ? '展开' : '收起',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSilver,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    expanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: AppTheme.textSilver,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Toggle switch row
                        Row(
                          children: [
                            Text(
                              '启用人声',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            Spacer(),
                            Switch(
                              value: expanded,
                              onChanged: (v) => controller.vocalsEnabled.value = v,
                              activeColor: AppTheme.primaryColor,
                              inactiveThumbColor: AppTheme.textDarkGray,
                              inactiveTrackColor: AppTheme.textDarkGray.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                        // Expanded dropdown area
                        if (expanded) ...[
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface2,
                              borderRadius: AppTheme.radiusComfortableAll,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.selectedVoice.value,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppTheme.textLightGray,
                                ),
                                dropdownColor: AppTheme.surface3,
                                style: TextStyle(
                                  color: AppTheme.textWhite,
                                  fontSize: 15,
                                ),
                                items: [
                                  DropdownMenuItem(value: '男声', child: Text('男声')),
                                  DropdownMenuItem(value: '女声', child: Text('女声')),
                                  DropdownMenuItem(value: '中性', child: Text('中性')),
                                ],
                                onChanged: (v) {
                                  if (v != null) controller.selectedVoice.value = v;
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: 40),

          // ---------- Generate Button ----------
          FadeInWidget(
            delayMs: 180,
            child: GestureDetector(
              onTap: () {
                // 防重复提交：正在生成中则忽略点击
                if (controller.isGenerating.value) return;
                controller.generateSong();
              },
              child: Container(
                height: 56,
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryToSecondary,
                  borderRadius: AppTheme.radiusFullPillAll,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                      blurRadius: 32,
                      spreadRadius: 0,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '✨ 生成歌曲',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textWhite,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Genre Pills with crystalTechGradient ----------
  Widget _buildGenrePills() {
    final options = ['流行', '摇滚', '嘻哈', '节奏布鲁斯', '电子', '低保真'];
    final selected = controller.selectedGenre.value;
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => controller.selectedGenre.value = opt,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryToSecondary : null,
              color: isSelected ? null : AppTheme.surfaceElevated,
              borderRadius: AppTheme.radiusFullPillAll,
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppTheme.borderSubtle.withValues(alpha: 0.5),
                width: 0.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.textWhite : AppTheme.textSilver,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------- Compact Tempo Slider ----------
  Widget _buildCompactTempoSlider() {
    final labels = ['慢', '中', '快'];
    final idx = controller.tempoValue.value.round();
    return Column(
      children: [
        // Speed label
        Text(
          labels[idx.clamp(0, 2)],
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
        ),
        SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.surfaceElevated,
            thumbColor: AppTheme.textWhite,
            overlayColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: controller.tempoValue.value,
            min: 0,
            max: 2,
            divisions: 2,
            onChanged: (v) => controller.tempoValue.value = v,
          ),
        ),
        // BPM hint
        Text(
          _bpmFromTempo(controller.tempoValue.value),
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textDim,
          ),
        ),
      ],
    );
  }

  String _bpmFromTempo(double tempo) {
    if (tempo <= 0.5) return '~80 BPM';
    if (tempo <= 1.5) return '~120 BPM';
    return '~160 BPM';
  }

  // =================================================================
  // GENERATING STATE  —  rotating gradient ring + 4-step progress
  // =================================================================
  Widget _buildGeneratingState() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          children: [
            SizedBox(height: 24),

            // ---------- Rotating Gradient Ring (CustomPainter) ----------
            FadeInWidget(
              child: SizedBox(
                width: 120,
                height: 120,
                child: _GradientRingPainter(
                  primaryColor: AppTheme.primaryColor,
                  secondaryColor: AppTheme.secondaryColor,
                ),
              ),
            ),
            SizedBox(height: 48),

            // ---------- 4-Step Progress ----------
            Obx(() => Column(
                  children: [
                    _buildProgressStage(
                      index: 0,
                      icon: '🎵',
                      title: '处理歌词',
                      isActive: controller.currentStage.value >= 0,
                      isCompleted: controller.currentStage.value > 0,
                    ),
                    SizedBox(height: 4),
                    _buildStageConnector(activated: controller.currentStage.value > 0),
                    SizedBox(height: 4),
                    _buildProgressStage(
                      index: 1,
                      icon: '🎶',
                      title: '创作旋律',
                      isActive: controller.currentStage.value >= 1,
                      isCompleted: controller.currentStage.value > 1,
                    ),
                    SizedBox(height: 4),
                    _buildStageConnector(activated: controller.currentStage.value > 1),
                    SizedBox(height: 4),
                    _buildProgressStage(
                      index: 2,
                      icon: '🗣️',
                      title: '生成人声',
                      isActive: controller.currentStage.value >= 2,
                      isCompleted: controller.currentStage.value > 2,
                    ),
                    SizedBox(height: 4),
                    _buildStageConnector(activated: controller.currentStage.value > 2),
                    SizedBox(height: 4),
                    _buildProgressStage(
                      index: 3,
                      icon: '🎛️',
                      title: '混音母带',
                      isActive: controller.currentStage.value >= 3,
                      isCompleted: controller.currentStage.value > 3,
                    ),
                  ],
                )),
            SizedBox(height: 48),

            // ---------- Cancel Button (small, gray) ----------
            GestureDetector(
              onTap: () => controller.cancelGeneration(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.textDarkGray.withValues(alpha: 0.25),
                  borderRadius: AppTheme.radiusFullPillAll,
                  border: Border.all(
                    color: AppTheme.borderSubtle.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '取消生成',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSilver,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Single progress stage ----------
  Widget _buildProgressStage({
    required int index,
    required String icon,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: AppTheme.glassCard(
        radius: AppTheme.radiusComfortable,
        addGlow: isActive && !isCompleted,
        opacity: 0.55,
      ),
      child: Row(
        children: [
          // Icon / status
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCompleted
                  ? LinearGradient(colors: [AppTheme.successColor, Color(0xFF059669)])
                  : isActive
                      ? AppTheme.crystalTechGradient
                      : null,
              color: !isActive && !isCompleted ? AppTheme.surface2 : null,
              border: !isActive && !isCompleted
                  ? Border.all(color: AppTheme.borderSubtle, width: 0.5)
                  : null,
              boxShadow: isActive && !isCompleted
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check, size: 18, color: AppTheme.textWhite)
                  : Text(
                      icon,
                      style: TextStyle(
                        fontSize: isActive ? 16 : 14,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive || isCompleted
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isCompleted
                        ? AppTheme.successColor
                        : isActive
                            ? AppTheme.textWhite
                            : AppTheme.textLightGray,
                  ),
                ),
                if (isActive && !isCompleted)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 800),
                    builder: (context, value, _) {
                      return Container(
                        margin: EdgeInsets.only(top: 6),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1.5),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.secondaryColor,
                            ],
                            stops: [0, value],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Connector line between stages ----------
  Widget _buildStageConnector({required bool activated}) {
    return Container(
      width: 2,
      height: 16,
      decoration: BoxDecoration(
        gradient: activated
            ? LinearGradient(
                colors: [AppTheme.successColor, AppTheme.primaryColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : LinearGradient(
                colors: [
                  AppTheme.borderSubtle.withValues(alpha: 0.2),
                  AppTheme.borderSubtle.withValues(alpha: 0.2),
                ],
              ),
      ),
    );
  }

  // =================================================================
  // RESULT STATE  —  cover + info + glass player + actions
  // =================================================================
  Widget _buildResultState() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 100, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- Album Cover (280×280) with waveform overlay ----------
          FadeInWidget(
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  gradient: AppTheme.crystalTechGradient,
                  borderRadius: AppTheme.radiusXLargeAll,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                      blurRadius: 60,
                      spreadRadius: 0,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppTheme.radiusXLargeAll,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Waveform CustomPaint overlay
                      CustomPaint(
                        painter: _WaveformPainter(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      // Subtle vignette & center icon
                      Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 72,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 28),

          // ---------- Song Info ----------
          FadeInWidget(
            delayMs: 60,
            child: Column(
              children: [
                Text(
                  'AI 生成的歌曲',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                    height: 1.2,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '🎤 ${controller.selectedVoice.value} · ${controller.selectedGenre.value}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSilver,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // ---------- Glass Player Controls ----------
          FadeInWidget(
            delayMs: 100,
            child: ClipRRect(
              borderRadius: AppTheme.radiusXLargeAll,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: AppTheme.fullGlassEffect(),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Waveform visualization mini
                      SizedBox(
                        height: 32,
                        child: CustomPaint(
                          size: Size(double.infinity, 32),
                          painter: _WaveformPainter(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            barCount: 28,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Progress bar
                      Row(
                        children: [
                          Text(
                            '0:00',
                            style: TextStyle(color: AppTheme.textDim, fontSize: 11),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: AppTheme.surfaceElevated,
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.35,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: LinearGradient(
                                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '3:45',
                            style: TextStyle(color: AppTheme.textDim, fontSize: 11),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      // Play controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _glassIconButton(Icons.skip_previous_rounded, () {
                            ToastUtil.info('上一首功能请在播放器中使用');
                          }),
                          SizedBox(width: 28),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: AppTheme.crystalTechGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 34,
                              color: AppTheme.textWhite,
                            ),
                          ),
                          SizedBox(width: 28),
                          _glassIconButton(Icons.skip_next_rounded, () {
                            ToastUtil.info('下一首功能请在播放器中使用');
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 32),

          // ---------- Action Buttons ----------
          // Row 1: Save / Publish
          FadeInWidget(
            delayMs: 140,
            child: Row(
              children: [
                Expanded(child: _glassActionButton(Icons.favorite_border, '保存', () => controller.saveToLibrary())),
                SizedBox(width: 12),
                Expanded(child: _glassActionButton(Icons.publish, '发布', () => controller.publishSong())),
              ],
            ),
          ),
          SizedBox(height: 12),
          // Row 2: Download / Share
          FadeInWidget(
            delayMs: 180,
            child: Row(
              children: [
                Expanded(child: _glassActionButton(Icons.download_rounded, '下载', () => controller.downloadSong())),
                SizedBox(width: 12),
                Expanded(child: _glassActionButton(Icons.share_rounded, '分享', () => controller.shareSong())),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Bottom: Regenerate
          FadeInWidget(
            delayMs: 220,
            child: GestureDetector(
              onTap: () => controller.regenerateSong(),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.borderSubtle.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                  borderRadius: AppTheme.radiusFullPillAll,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: AppTheme.textWhite),
                    SizedBox(width: 8),
                    Text(
                      '重新生成',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.borderSubtle.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 22, color: Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }

  Widget _glassActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: AppTheme.glassCard(
          radius: AppTheme.radiusComfortable,
          tint: AppTheme.surfaceElevated,
          opacity: 0.55,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.textWhite),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// CUSTOM PAINTERS
// =====================================================================

/// Rotating gradient ring — used in generating state
class _GradientRingPainter extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;

  _GradientRingPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<_GradientRingPainter> createState() => _GradientRingPainterState();
}

class _GradientRingPainterState extends State<_GradientRingPainter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotationWidget(
      listenable: _controller,
      primaryColor: widget.primaryColor,
      secondaryColor: widget.secondaryColor,
    );
  }
}

class AnimatedRotationWidget extends AnimatedWidget {
  final Color primaryColor;
  final Color secondaryColor;

  AnimatedRotationWidget({
    super.key,
    required super.listenable,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return CustomPaint(
      painter: _RingPainter(
        rotation: animation.value * 2 * math.pi,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
      ),
      size: Size.square(120),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double rotation;
  final Color primaryColor;
  final Color secondaryColor;

  _RingPainter({
    required this.rotation,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw gradient arc segments
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final segments = 8;
    for (int i = 0; i < segments; i++) {
      final startAngle = rotation + (i * 2 * math.pi / segments);
      final sweepAngle = math.pi / segments * 0.85;

      final t = i / (segments - 1);
      final color = Color.lerp(primaryColor, secondaryColor, t)!;

      paint.color = color.withValues(alpha: 0.6 + (i % 2 == 0 ? 0.3 : 0.0));
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    // Outer glow ring
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);
    glowPaint.shader = SweepGradient(
      startAngle: rotation,
      endAngle: rotation + 2 * math.pi,
      colors: [
        primaryColor.withValues(alpha: 0.15),
        secondaryColor.withValues(alpha: 0.15),
        primaryColor.withValues(alpha: 0.15),
      ],
    ).createShader(rect);
    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.rotation != rotation;
}

/// Waveform line overlay — used on album cover and player
class _WaveformPainter extends CustomPainter {
  final Color color;
  final int barCount;

  _WaveformPainter({
    this.color = Colors.white54,
    this.barCount = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barWidth = size.width / (barCount * 2);
    
    for (int i = 0; i < barCount; i++) {
      // Pseudo-random height based on i
      final h = 4 + math.sin(i * 0.9) * 6 + math.cos(i * 0.4) * 4;
      final barHeight = h.clamp(4, size.height / 2.2);
      final x = barWidth * (2 * i + 1);

      paint.strokeWidth = barWidth * 0.6;
      canvas.drawLine(
        Offset(x, centerY - barHeight),
        Offset(x, centerY + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) => false;
}


