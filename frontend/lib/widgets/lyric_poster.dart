import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/utils/toast_util.dart';

/// 歌词海报生成组件
/// 封面模糊背景 + 大号歌词文字 + 歌曲信息 + App二维码占位 + Logo水印
class LyricPosterUtil {
  /// 显示歌词海报预览
  static Future<void> showLyricPosterPreview({
    required String lyric,
    required String title,
    required String artist,
    String? coverUrl,
  }) async {
    final GlobalKey posterKey = GlobalKey();

    await Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: AppTheme.surface3,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
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
              '歌词海报',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: posterKey,
                  child: _LyricPosterWidget(
                    lyric: lyric,
                    title: title,
                    artist: artist,
                    coverUrl: coverUrl,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _savePoster(posterKey),
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
                      onPressed: () => _sharePoster(posterKey),
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

  /// 捕获海报为图片字节
  static Future<Uint8List?> _capturePoster(GlobalKey key) async {
    try {
      final context = key.currentContext;
      if (context == null) {
        debugPrint('海报组件未挂载，无法捕获');
        return null;
      }
      final RenderRepaintBoundary boundary =
          context.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('捕获歌词海报失败: $e');
      return null;
    }
  }

  /// 保存海报到本地
  static Future<void> _savePoster(GlobalKey key) async {
    final bytes = await _capturePoster(key);
    if (bytes == null) {
      ToastUtil.error('保存失败');
      return;
    }
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'aimusic_lyric_poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      ToastUtil.success('海报已保存到: ${file.path}');
      Get.back();
    } catch (e) {
      ToastUtil.error('保存失败: $e');
    }
  }

  /// 分享海报
  static Future<void> _sharePoster(GlobalKey key) async {
    final bytes = await _capturePoster(key);
    if (bytes == null) {
      ToastUtil.error('生成海报失败');
      return;
    }
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'aimusic_lyric_poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      ToastUtil.success('海报已生成，请使用系统分享功能');
      Get.back();
    } catch (e) {
      ToastUtil.error('分享失败: $e');
    }
  }
}

/// 歌词海报 Widget
/// 封面模糊背景 + 大号歌词文字 + 歌曲信息 + App二维码占位 + Logo水印
class _LyricPosterWidget extends StatelessWidget {
  final String lyric;
  final String title;
  final String artist;
  final String? coverUrl;

  const _LyricPosterWidget({
    required this.lyric,
    required this.title,
    required this.artist,
    this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 460,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 封面图片模糊背景
            _buildBlurBackground(),
            // 深色遮罩层
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // 装饰光晕
            _buildDecorGlow(),
            // 主内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                children: [
                  // 歌词文字（核心展示 - 大号白色带阴影）
                  Expanded(
                    child: Center(
                      child: Text(
                        lyric,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.8,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 分隔线
                  Container(
                    width: 40,
                    height: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  // 歌曲标题
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 歌手名
                  Text(
                    artist,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  // 底部信息：App二维码占位 + Logo
                  _buildBottomSection(),
                ],
              ),
            ),
            // 右下角 App Logo
            Positioned(
              right: 16,
              bottom: 16,
              child: _buildAppLogo(),
            ),
          ],
        ),
      ),
    );
  }

  /// 封面图片模糊背景
  Widget _buildBlurBackground() {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // 封面图片
          CachedNetworkImage(
            imageUrl: coverUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _buildDefaultBackground(),
          ),
          // 高斯模糊效果
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ],
      );
    }
    return _buildDefaultBackground();
  }

  /// 默认背景（无封面时）
  Widget _buildDefaultBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
      ),
    );
  }

  /// 装饰光晕效果
  Widget _buildDecorGlow() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
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
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1.2,
                colors: [
                  AppTheme.brandPurple.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 底部信息区域：歌曲名 + 歌手名 + App二维码占位
  Widget _buildBottomSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 左侧：二维码占位
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.qr_code_rounded,
              size: 32,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 右侧：扫码提示
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '扫码听歌',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '音浪AI',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 右下角 App Logo 文字
  Widget _buildAppLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note_rounded,
            size: 12,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '音浪AI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
