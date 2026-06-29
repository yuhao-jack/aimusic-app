import 'package:flutter/foundation.dart';

/// API 配置类 — 统一管理服务器地址
/// 支持通过 --dart-define 注入环境变量：
///   flutter run --dart-define=API_HOST=192.168.1.100 --dart-define=API_PORT=8080
class ApiConfig {
  ApiConfig._();

  /// 从环境变量读取服务器地址，默认 localhost
  static const String _envHost = String.fromEnvironment('API_HOST', defaultValue: '');
  static const int _envPort = int.fromEnvironment('API_PORT', defaultValue: 0);

  /// 服务器基础地址（不含 /api/v1/ 路径）
  static String get serverBaseUrl {
    final host = _envHost.isNotEmpty ? _envHost : _defaultHost;
    final port = _envPort > 0 ? _envPort : 8080;
    return 'http://$host:$port';
  }

  /// 根据平台的默认主机地址
  // 注意：以下 IP 地址仅用于本地开发调试。
  // 生产环境应通过 --dart-define=API_HOST=your-domain.com 注入域名，
  // 或修改此处为正式域名（如 api.aimusic.app）。
  static String get _defaultHost {
    if (kIsWeb) {
      return 'localhost';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return '192.168.83.182';
    } else {
      return '192.168.83.182';
    }
  }

  /// API 完整基础路径（含 /api/v1/）
  static String get apiBaseUrl => '$serverBaseUrl/api/v1/';

  /// 分享链接前缀（H5 页面地址，用于生成分享链接和海报二维码）
  static String get shareBaseUrl => serverBaseUrl;
}
