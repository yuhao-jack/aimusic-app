import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/utils/toast_util.dart';

/// 分享海报生成工具
/// 使用 Widget 组合 + RepaintBoundary 生成海报图片
class PosterUtil {
  /// 显示海报预览并提供保存/分享选项
  static Future<void> showPosterPreview({
    required String title,
    required String artist,
    String? coverUrl,
  }) async {
    // 用于捕获海报图片的 GlobalKey
    final GlobalKey posterKey = GlobalKey();

    await Get.bottomSheet(
      Container(
        height: Get.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 顶部拖拽指示条
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textDarkGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '分享海报',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 20),
            // 海报预览区域
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: posterKey,
                  child: _PosterWidget(
                    title: title,
                    artist: artist,
                    coverUrl: coverUrl,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 操作按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _savePoster(posterKey);
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('保存图片'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textWhite,
                        side: const BorderSide(color: AppTheme.borderGray),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _sharePoster(posterKey);
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('分享'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: AppTheme.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// 将海报捕获为图片
  static Future<Uint8List?> _capturePoster(GlobalKey key) async {
    try {
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('捕获海报失败: $e');
      return null;
    }
  }

  /// 保存海报到临时目录
  static Future<void> _savePoster(GlobalKey key) async {
    final bytes = await _capturePoster(key);
    if (bytes == null) {
      ToastUtil.error('保存失败');
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'aimusic_poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      ToastUtil.success('海报已保存到: ${file.path}');
      Get.back();
    } catch (e) {
      ToastUtil.error('保存失败: $e');
    }
  }

  /// 分享海报（目前仅复制提示）
  static Future<void> _sharePoster(GlobalKey key) async {
    final bytes = await _capturePoster(key);
    if (bytes == null) {
      ToastUtil.error('生成海报失败');
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'aimusic_poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      ToastUtil.success('海报已生成，请使用系统分享功能');
      Get.back();
    } catch (e) {
      ToastUtil.error('分享失败: $e');
    }
  }
}

/// 海报 Widget 组件
/// 深色渐变背景 + 歌曲封面 + 标题 + 歌手 + 二维码占位 + App Logo
class _PosterWidget extends StatelessWidget {
  final String title;
  final String artist;
  final String? coverUrl;

  const _PosterWidget({
    required this.title,
    required this.artist,
    this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 背景装饰渐变
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    AppTheme.brandIndigo.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 主要内容
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 歌曲封面（圆形）
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.brandIndigo.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandIndigo.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: coverUrl != null && coverUrl!.isNotEmpty
                        ? Image.network(
                            coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultCover(),
                          )
                        : _buildDefaultCover(),
                  ),
                ),
                const SizedBox(height: 28),
                // 歌曲标题
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // 歌手名
                Text(
                  artist,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSilver.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 36),
                // 二维码占位区域
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_rounded,
                        size: 32,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'aimusic.app',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // App Logo 文字
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: 16,
                      color: AppTheme.brandIndigo.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '音浪 AI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandIndigo.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 默认封面图标
  Widget _buildDefaultCover() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brandIndigo, AppTheme.brandPurple],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 48,
          color: Colors.white24,
        ),
      ),
    );
  }
}
