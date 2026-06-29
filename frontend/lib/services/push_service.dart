import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

/// 推送通知服务
/// 基于 flutter_local_notifications 实现本地推送通知
/// 支持：新歌发布通知、关注动态通知、签到提醒
class PushService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 通知是否已初始化
  bool _initialized = false;

  /// 通知点击回调
  Function(String? payload)? onNotificationTapped;

  @override
  void onInit() {
    super.onInit();
    _initNotifications();
  }

  /// 初始化通知插件
  Future<void> _initNotifications() async {
    if (_initialized) return;

    // Android 初始化配置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化配置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTapped?.call(response.payload);
      },
    );

    _initialized = true;
    debugPrint('推送通知服务初始化完成');
  }

  /// 请求通知权限（iOS）
  Future<bool> requestPermission() async {
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// 发送新歌发布通知
  Future<void> showNewSongNotification({
    required int songId,
    required String title,
    required String singer,
  }) async {
    await _showNotification(
      id: songId.hashCode.abs() % 100000,
      title: '新歌发布',
      body: '$singer 的新歌《$title》已上线，快来听听吧！',
      payload: 'new_song:$songId',
      channelId: 'new_song',
      channelName: '新歌发布',
    );
  }

  /// 发送关注动态通知
  Future<void> showFollowUpdateNotification({
    required int userId,
    required String nickname,
    required String action,
  }) async {
    await _showNotification(
      id: userId.hashCode.abs() % 100000 + 50000,
      title: '关注动态',
      body: '$nickname $action',
      payload: 'follow_update:$userId',
      channelId: 'follow_update',
      channelName: '关注动态',
    );
  }

  /// 发送签到提醒通知
  Future<void> showCheckInReminder() async {
    await _showNotification(
      id: 99999,
      title: '签到提醒',
      body: '今天还没有签到哦，签到可获得音币奖励！',
      payload: 'check_in',
      channelId: 'reminder',
      channelName: '提醒',
    );
  }

  /// 发送VIP到期提醒通知
  /// [daysLeft] 剩余天数
  Future<void> showVIPExpiringNotification({required int daysLeft}) async {
    String body;
    if (daysLeft <= 0) {
      body = '您的VIP会员已到期，续费即可继续享受专属特权！';
    } else if (daysLeft <= 3) {
      body = '您的VIP会员还有${daysLeft}天到期，续费享专属特权！';
    } else {
      body = '您的VIP会员即将到期，提前续费享优惠！';
    }

    await _showNotification(
      id: 88888,
      title: 'VIP到期提醒',
      body: body,
      payload: 'vip_expire',
      channelId: 'reminder',
      channelName: '提醒',
    );
  }

  /// 通用通知发送方法
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required String channelId,
    required String channelName,
  }) async {
    if (!_initialized) {
      await _initNotifications();
    }

    // Android 通知详情
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    // iOS 通知详情
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(id, title, body, details, payload: payload);
      debugPrint('通知已发送: $title');
    } catch (e) {
      debugPrint('通知发送失败: $e');
    }
  }

  /// 取消指定通知
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
