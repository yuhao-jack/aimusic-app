import 'package:flutter/material.dart';

/// 优化的长列表组件
/// 对于长列表（>100项）使用 itemExtent 提升性能
/// 添加 addAutomaticKeepAlives: false 减少内存占用
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double? itemExtent;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? separator;
  final Widget? emptyWidget;
  final Axis scrollDirection;
  final bool reverse;
  final bool primary;

  OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemExtent,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.separator,
    this.emptyWidget,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    // 如果列表为空，显示空状态
    if (items.isEmpty) {
      return emptyWidget ?? 
        Center(
          child: Text(
            '暂无数据',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        );
    }

    // 如果有分隔符，使用 ListView.separated
    if (separator != null) {
      return ListView.separated(
        controller: controller,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        scrollDirection: scrollDirection,
        reverse: reverse,
        primary: primary,
        itemCount: items.length,
        // 减少内存占用
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          return itemBuilder(context, items[index], index);
        },
        separatorBuilder: (context, index) => separator!,
      );
    }

    // 没有分隔符时使用 ListView.builder
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      itemCount: items.length,
      // 对于长列表，使用 itemExtent 提升性能
      itemExtent: itemExtent,
      // 减少内存占用
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

/// 优化的网格列表组件
class OptimizedGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? emptyWidget;
  final Axis scrollDirection;
  final bool reverse;

  OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.emptyWidget,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    // 如果列表为空，显示空状态
    if (items.isEmpty) {
      return emptyWidget ?? 
        Center(
          child: Text(
            '暂无数据',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        );
    }

    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      scrollDirection: scrollDirection,
      reverse: reverse,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      // 减少内存占用
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

/// 分页加载列表组件
class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final double? itemExtent;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final Widget? separator;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? noMoreWidget;

  PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = true,
    this.isLoading = false,
    this.itemExtent,
    this.controller,
    this.padding,
    this.separator,
    this.emptyWidget,
    this.loadingWidget,
    this.noMoreWidget,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late ScrollController _scrollController;
  bool _isLoadMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadMore || !widget.hasMore || widget.isLoading) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // 距离底部200像素时开始加载

    if (maxScroll - currentScroll <= delta) {
      _isLoadMore = true;
      if (widget.onLoadMore != null) {
        widget.onLoadMore!().then((_) {
          _isLoadMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果列表为空，显示空状态
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? 
        Center(
          child: Text(
            '暂无数据',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      // 对于长列表，使用 itemExtent 提升性能
      itemExtent: widget.itemExtent,
      // 减少内存占用
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        // 最后一项显示加载更多或没有更多
        if (index == widget.items.length) {
          if (widget.isLoading) {
            return widget.loadingWidget ?? 
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
          }
          return widget.noMoreWidget ?? 
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '没有更多了',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            );
        }

        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }
}