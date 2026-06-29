/// 内存缓存工具类，用于网络请求结果缓存
class CacheUtil {
  static final CacheUtil _instance = CacheUtil._internal();
  factory CacheUtil() => _instance;
  CacheUtil._internal();

  /// 缓存存储: key -> CacheEntry
  final Map<String, CacheEntry> _cache = {};

  /// 默认缓存时间：5分钟
  static const Duration defaultDuration = Duration(minutes: 5);

  /// 获取缓存数据，无效或不存在则返回null
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null || !entry.isValid) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  /// 设置缓存，可自定义过期时间
  void set<T>(String key, T data, {Duration? duration}) {
    _cache[key] = CacheEntry(
      data: data,
      expireAt: DateTime.now().add(duration ?? defaultDuration),
    );
  }

  /// 删除指定缓存
  void remove(String key) {
    _cache.remove(key);
  }

  /// 清空所有缓存
  void clear() {
    _cache.clear();
  }

  /// 检查缓存是否有效
  bool isValid(String key) {
    return _cache[key]?.isValid ?? false;
  }
}

/// 缓存条目，包含数据和过期时间
class CacheEntry {
  final dynamic data;
  final DateTime expireAt;

  CacheEntry({required this.data, required this.expireAt});

  bool get isValid => DateTime.now().isBefore(expireAt);
}
