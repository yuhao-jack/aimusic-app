import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:aimusic_app/services/api_service.dart';

/// 用户行为埋点服务
class TrackingService extends GetxService {
  final ApiService _api = Get.find<ApiService>();
  
  // 事件缓冲队列
  final List<Map<String, dynamic>> _eventQueue = [];
  
  // 批量上报阈值
  static const int _batchSize = 10;
  
  // 上报间隔（秒）
  static const int _flushInterval = 30;
  
  String _platform = '';
  String _appVersion = '';

  @override
  void onInit() {
    super.onInit();
    _initPlatformInfo();
    // 定时上报
    Future.delayed(const Duration(seconds: _flushInterval), _flushLoop);
  }

  /// 初始化平台信息
  Future<void> _initPlatformInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _platform = GetPlatform.isIOS ? 'ios' : 'android';
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('获取平台信息失败: $e');
    }
  }

  /// 定时上报循环
  Future<void> _flushLoop() async {
    while (true) {
      await Future.delayed(const Duration(seconds: _flushInterval));
      await _flush();
    }
  }

  /// 追踪事件
  void track(String eventName, {String eventType = 'custom', Map<String, String>? params}) {
    _eventQueue.add({
      'event_name': eventName,
      'event_type': eventType,
      'params': params ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // 达到批量阈值时上报
    if (_eventQueue.length >= _batchSize) {
      _flush();
    }
  }

  /// 追踪页面访问
  void trackPageView(String pageName, {String? from}) {
    track('page_view', eventType: 'page_view', params: {
      'page': pageName,
      if (from != null) 'from': from,
    });
  }

  /// 追踪歌曲播放
  void trackSongPlay(int songId, {String? source}) {
    track('song_play', eventType: 'song_play', params: {
      'song_id': songId.toString(),
      if (source != null) 'source': source,
    });
  }

  /// 追踪歌曲点赞
  void trackSongLike(int songId) {
    track('song_like', eventType: 'social', params: {
      'song_id': songId.toString(),
    });
  }

  /// 追踪AI创作
  void trackAICreate(String type, {bool success = true}) {
    track(success ? 'ai_create_success' : 'ai_create_fail', 
      eventType: 'ai_create', 
      params: {'type': type});
  }

  /// 追踪分享
  void trackShare(String contentType, int contentId) {
    track('share', eventType: 'social', params: {
      'content_type': contentType,
      'content_id': contentId.toString(),
    });
  }

  /// 追踪搜索
  void trackSearch(String keyword) {
    track('search', eventType: 'search', params: {
      'keyword': keyword,
    });
  }

  /// 追踪签到
  void trackCheckIn() {
    track('check_in', eventType: 'engagement');
  }

  /// 追踪购买
  void trackPurchase(String type, int amount) {
    track('purchase', eventType: 'purchase', params: {
      'type': type,
      'amount': amount.toString(),
    });
  }

  /// 上报事件到服务器
  Future<void> _flush() async {
    if (_eventQueue.isEmpty) return;
    
    final events = List<Map<String, dynamic>>.from(_eventQueue);
    _eventQueue.clear();
    
    try {
      await _api.post('/events/track', data: {
        'events': events,
        'platform': _platform,
        'app_version': _appVersion,
      });
    } catch (e) {
      debugPrint('埋点上报失败: $e');
      // 失败时重新加入队列（限制队列大小防止内存溢出）
      if (_eventQueue.length < 100) {
        _eventQueue.addAll(events);
      }
    }
  }

  @override
  void onClose() {
    _flush(); // 关闭前上报剩余事件
    super.onClose();
  }
}
