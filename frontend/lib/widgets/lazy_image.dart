import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 懒加载图片组件
/// 只在可见区域内加载图片，提升性能
class LazyImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  bool _isVisible = false;
  bool _hasLoaded = false;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 延迟检查可见性
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (_hasLoaded) return;
    
    final RenderObject? renderObject = _key.currentContext?.findRenderObject();
    if (renderObject == null) return;

    final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);
    final RevealedOffset revealedOffset = viewport.getOffsetToReveal(renderObject, 0.0);
    
    // 获取滚动位置
    final ScrollableState? scrollable = Scrollable.of(context);
    if (scrollable == null) return;

    final double viewportHeight = scrollable.position.viewportDimension;
    final double scrollOffset = scrollable.position.pixels;
    
    // 检查图片是否在可见区域内
    final double imageTop = revealedOffset.offset;
    final double imageBottom = imageTop + (widget.height ?? 100);
    
    if (imageTop < scrollOffset + viewportHeight && imageBottom > scrollOffset) {
      setState(() {
        _isVisible = true;
        _hasLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果图片URL为空，直接显示错误占位符
    if (widget.imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    return Container(
      key: _key,
      child: _isVisible ? _buildImage() : _buildPlaceholder(),
    );
  }

  /// 构建图片组件
  Widget _buildImage() {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
        memCacheWidth: widget.width?.toInt(),
        memCacheHeight: widget.height?.toInt(),
      ),
    );
  }

  /// 构建占位符
  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: widget.placeholder ?? 
        Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor.withOpacity(0.5),
              ),
            ),
          ),
        ),
    );
  }

  /// 构建错误占位符
  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: widget.errorWidget ?? 
        Icon(
          Icons.music_note,
          color: Colors.grey[400],
          size: 32,
        ),
    );
  }
}

/// 圆形懒加载头像组件
class LazyAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LazyAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LazyImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      placeholder: placeholder ?? 
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: Colors.grey[400],
            size: size * 0.6,
          ),
        ),
      errorWidget: errorWidget ?? 
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: Colors.grey[400],
            size: size * 0.6,
          ),
        ),
    );
  }
}