import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aimusic_app/utils/api_config.dart';
import 'package:aimusic_app/utils/toast_util.dart';
import 'package:aimusic_app/utils/cache_util.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/services/auth_service.dart';

class HttpUtil {
  static final HttpUtil _instance = HttpUtil._internal();
  factory HttpUtil() => _instance;

  late Dio dio;

  // 根据平台选择合适的 baseUrl
  static String get baseUrl => ApiConfig.apiBaseUrl;

  // 请求队列 - 用于Token刷新时等待的请求
  final List<Function> _pendingRequests = [];
  bool _isRefreshing = false;
  // 标记是否正在处理刷新token请求
  bool _isRefreshTokenRequest = false;

  HttpUtil._internal() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    dio = Dio(options);

    // 添加拦截器
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 添加token - 使用同步方式获取，避免阻塞
        try {
          final prefs = await SharedPreferences.getInstance();
          String? token = prefs.getString('token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          debugPrint('获取token失败: $e');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 统一处理响应 — 后端统一返回 code==0 表示成功
        // HTTP层面 statusCode 200 + body.code 0 才是真正成功
        if (response.data != null &&
            response.data is Map &&
            response.data['code'] != null &&
            response.data['code'] != 0 &&
            response.data['code'] != 200) {
          // 不在这里弹 Toast，让调用方自己处理
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              message: response.data['msg'] ?? response.data['message'] ?? '请求失败',
            ),
          );
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        // 401 → token过期，尝试刷新
        if (e.response?.statusCode == 401) {
          await _handle401Error(e, handler);
          return;
        }
        // 429 → 请求过于频繁
        if (e.response?.statusCode == 429) {
          _handle429Error(e);
          return handler.next(e);
        }
        // 402 → 需要付费（音币余额不足）
        if (e.response?.statusCode == 402) {
          _handle402Error(e);
          return handler.next(e);
        }
        // 其他错误：静默处理，由调用方决定是否提示用户
        if (e.type != DioExceptionType.cancel) {
          debugPrint('网络错误: ${e.message}');
        }
        return handler.next(e);
      },
    ));
  }

  // 处理401错误
  Future<void> _handle401Error(DioException e, ErrorInterceptorHandler handler) async {
    // 如果刷新token的请求本身返回401，直接跳转不重试
    if (_isRefreshTokenRequest) {
      debugPrint('刷新token请求返回401，直接跳转登录页');
      await _clearAndRedirect();
      return handler.reject(e);
    }

    if (_isRefreshing) {
      // 正在刷新Token，将请求入队等待
      _pendingRequests.add(() => _retryRequest(e.requestOptions, handler));
      return;
    }

    _isRefreshing = true;

    try {
      final AuthService authService = Get.find<AuthService>();
      _isRefreshTokenRequest = true;
      final refreshSuccess = await authService.refreshToken();
      _isRefreshTokenRequest = false;

      if (refreshSuccess) {
        _processPendingRequests();
        await _retryRequest(e.requestOptions, handler);
      } else {
        await _clearAndRedirect();
        return handler.reject(e);
      }
    } catch (error) {
      debugPrint('处理401错误失败: $error');
      _isRefreshTokenRequest = false;
      await _clearAndRedirect();
      return handler.reject(e);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _clearAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_info');
    Get.offAllNamed(AppRoutes.login);
    ToastUtil.showWarning('登录已过期，请重新登录');
  }

  // 处理429错误 - 请求过于频繁
  void _handle429Error(DioException e) {
    final retryAfter = e.response?.headers.value('Retry-After');
    final message = retryAfter != null 
        ? '请求过于频繁，请 $retryAfter 秒后再试'
        : '请求过于频繁，请稍后再试';
    ToastUtil.showWarning(message);
  }

  // 处理402错误 - 需要付费（音币余额不足）
  void _handle402Error(DioException e) {
    final responseData = e.response?.data;
    String message = '音币余额不足';
    if (responseData is Map && responseData['msg'] != null) {
      message = responseData['msg'];
    }
    ToastUtil.showError(message);
    // 跳转到会员中心充值
    Get.toNamed(AppRoutes.membership);
  }

  // 重试请求
  Future<void> _retryRequest(RequestOptions requestOptions, ErrorInterceptorHandler handler) async {
    try {
      // 重新获取最新token
      final prefs = await SharedPreferences.getInstance();
      final newToken = prefs.getString('token');
      requestOptions.headers['Authorization'] = 'Bearer $newToken';

      // 创建新的请求选项（避免baseUrl路径拼接问题）
      final options = Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      );
      final response = await dio.request(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options,
        cancelToken: requestOptions.cancelToken,
      );
      handler.resolve(response);
    } catch (e) {
      handler.next(e as DioException);
    }
  }

  // 处理队列中的请求
  void _processPendingRequests() {
    for (var request in _pendingRequests) {
      request();
    }
    _pendingRequests.clear();
  }

  // ===== 公开接口 =====
  // 所有方法支持可选的 CancelToken

  // GET请求，支持可选的缓存
  Future<Response> get(String path, {Map<String, dynamic>? params, CancelToken? cancelToken, Duration? cacheDuration}) async {
    // 如果指定了缓存时间，先检查缓存
    if (cacheDuration != null) {
      final cacheKey = _buildCacheKey(path, params);
      final cached = CacheUtil().get<Response>(cacheKey);
      if (cached != null) {
        return cached;
      }
      // 缓存未命中，请求成功后存入缓存
      final response = await dio.get(path, queryParameters: params, cancelToken: cancelToken);
      CacheUtil().set(cacheKey, response, duration: cacheDuration);
      return response;
    }
    return await dio.get(path, queryParameters: params, cancelToken: cancelToken);
  }

  /// 构建缓存key：路径 + 查询参数
  String _buildCacheKey(String path, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return path;
    // 参数排序后拼接，确保相同参数生成相同key
    final sortedKeys = params.keys.toList()..sort();
    final parts = sortedKeys.map((k) => '$k=${params[k]}');
    return '$path?${parts.join('&')}';
  }

  // POST请求
  Future<Response> post(String path, {dynamic data, CancelToken? cancelToken}) async {
    return await dio.post(path, data: data, cancelToken: cancelToken);
  }

  // PUT请求
  Future<Response> put(String path, {dynamic data, CancelToken? cancelToken}) async {
    return await dio.put(path, data: data, cancelToken: cancelToken);
  }

  // DELETE请求
  Future<Response> delete(String path, {CancelToken? cancelToken}) async {
    return await dio.delete(path, cancelToken: cancelToken);
  }
}
