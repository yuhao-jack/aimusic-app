import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../utils/http_util.dart';

class ApiService extends GetxService {
  // 使用全局配置好的Dio实例
  Dio get _dio => HttpUtil().dio;

  /// GET 请求，支持可选缓存
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, CancelToken? cancelToken, Duration? cacheDuration}) async {
    if (cacheDuration != null) {
      // 委托给 HttpUtil 处理缓存逻辑
      final response = await HttpUtil().get(path, params: queryParameters, cancelToken: cancelToken, cacheDuration: cacheDuration);
      return response.data;
    }
    final response = await _dio.get(path, queryParameters: queryParameters, cancelToken: cancelToken);
    return response.data;
  }

  Future<dynamic> post(String path, {dynamic data, CancelToken? cancelToken}) async {
    final response = await _dio.post(path, data: data, cancelToken: cancelToken);
    return response.data;
  }

  Future<dynamic> put(String path, {dynamic data, CancelToken? cancelToken}) async {
    final response = await _dio.put(path, data: data, cancelToken: cancelToken);
    return response.data;
  }

  Future<dynamic> delete(String path, {CancelToken? cancelToken}) async {
    final response = await _dio.delete(path, cancelToken: cancelToken);
    return response.data;
  }

  // 上传文件
  Future<dynamic> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? extraData,
    CancelToken? cancelToken,
  }) async {
    String fileName = filePath.split('/').last;
    FormData formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath, filename: fileName),
      if (extraData != null) ...extraData,
    });
    final response = await _dio.post(path, data: formData, cancelToken: cancelToken);
    return response.data;
  }
}
