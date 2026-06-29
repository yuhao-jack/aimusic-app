import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:aimusic_app/utils/http_util.dart';

/// 一起听房间 WebSocket 服务
/// 负责 WebSocket 连接管理、消息收发、自动重连
class WebSocketService extends GetxService {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  /// 当前连接的房间ID
  int? _currentRoomId;

  /// 连接状态
  final RxBool isConnected = false.obs;

  /// 在线人数
  final RxInt onlineCount = 0.obs;

  /// 消息流控制器
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// 接收消息的流
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// 重连次数
  int _reconnectAttempts = 0;

  /// 最大重连次数
  static const int _maxReconnectAttempts = 5;

  /// 重连间隔（秒）
  static const int _reconnectInterval = 3;

  /// 连接到房间 WebSocket
  Future<void> connect(int roomId) async {
    // 断开已有连接
    disconnect();
    _currentRoomId = roomId;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  /// 执行实际连接
  Future<void> _doConnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // 构建 WebSocket URL
      final baseUrl = HttpUtil.baseUrl
          .replaceAll('http://', 'ws://')
          .replaceAll('https://', 'wss://');
      final url = '$baseUrl/api/v1/music/together/ws/$_currentRoomId?token=$token';

      _channel = WebSocketChannel.connect(Uri.parse(url));

      // 监听消息
      _channel!.stream.listen(
        (data) {
          _reconnectAttempts = 0; // 收到消息则重置重连计数
          try {
            final Map<String, dynamic> msg = jsonDecode(data);
            _handleMessage(msg);
          } catch (e) {
            debugPrint('WebSocket 消息解析失败: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket 错误: $error');
          isConnected.value = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket 连接关闭');
          isConnected.value = false;
          _scheduleReconnect();
        },
      );

      isConnected.value = true;
      _startHeartbeat();
      debugPrint('WebSocket 已连接到房间 $_currentRoomId');
    } catch (e) {
      debugPrint('WebSocket 连接失败: $e');
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  /// 处理接收到的消息
  void _handleMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;

    switch (type) {
      case 'heartbeat_ack':
        // 心跳响应，更新在线人数
        if (msg['payload'] is Map) {
          onlineCount.value = msg['payload']['online_count'] ?? 0;
        }
        break;
      case 'user_join':
        if (msg['payload'] is Map) {
          onlineCount.value = msg['payload']['online_count'] ?? 0;
        }
        _messageController.add(msg);
        break;
      case 'user_leave':
        if (msg['payload'] is Map) {
          onlineCount.value = msg['payload']['online_count'] ?? 0;
        }
        _messageController.add(msg);
        break;
      default:
        // 其他消息（play/pause/seek/switch_song/chat）转发给监听者
        _messageController.add(msg);
    }
  }

  /// 发送消息
  void sendMessage(String type, {Map<String, dynamic>? payload}) {
    if (!isConnected.value || _channel == null) {
      debugPrint('WebSocket 未连接，无法发送消息');
      return;
    }

    final msg = jsonEncode({
      'type': type,
      'payload': payload ?? {},
    });

    _channel!.sink.add(msg);
  }

  /// 发送播放控制消息
  void sendPlay() => sendMessage('play');
  void sendPause() => sendMessage('pause');
  void sendSeek(double position) => sendMessage('seek', payload: {'position': position});
  void sendSwitchSong(int songId) => sendMessage('switch_song', payload: {'song_id': songId});
  void sendChat(String content) => sendMessage('chat', payload: {'content': content});

  /// 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      sendMessage('heartbeat');
    });
  }

  /// 计划重连
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket 重连次数已达上限');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: _reconnectInterval * (_reconnectAttempts + 1)),
      () {
        if (_currentRoomId != null && !isConnected.value) {
          _reconnectAttempts++;
          debugPrint('WebSocket 第 $_reconnectAttempts 次重连...');
          _doConnect();
        }
      },
    );
  }

  /// 断开连接
  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    isConnected.value = false;
    onlineCount.value = 0;
    _currentRoomId = null;
    _reconnectAttempts = 0;
  }

  @override
  void onClose() {
    disconnect();
    _messageController.close();
    super.onClose();
  }
}
