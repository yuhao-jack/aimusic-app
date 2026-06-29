import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';

/// 会员与音币商业化服务
class MembershipService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  /// 获取当前用户的会员信息（等级、到期时间、音币余额）
  Future<Map<String, dynamic>?> getMembershipInfo() async {
    try {
      final response = await _api.get('/membership/info');
      if (response['code'] == 0) {
        return Map<String, dynamic>.from(response['data'] ?? {});
      }
      return null;
    } catch (e) {
      debugPrint('获取会员信息失败: $e');
      return null;
    }
  }

  /// 获取VIP套餐列表
  Future<List<Map<String, dynamic>>> getVIPPlans() async {
    try {
      final response = await _api.get('/membership/vip-plans');
      debugPrint('VIP套餐响应: $response');
      if (response != null && response['code'] == 0) {
        final data = response['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      debugPrint('获取VIP套餐失败: $e');
      return [];
    }
  }

  /// 获取音币充值包列表
  Future<List<Map<String, dynamic>>> getCoinPackages() async {
    try {
      final response = await _api.get('/membership/coin-packages');
      debugPrint('音币充值包响应: $response');
      if (response != null && response['code'] == 0) {
        final data = response['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      debugPrint('获取音币充值包失败: $e');
      return [];
    }
  }

  /// 购买VIP套餐
  Future<bool> buyVIP(int planId, {String payMethod = 'alipay'}) async {
    try {
      final response = await _api.post('/membership/buy-vip', data: {
        'plan_id': planId,
        'pay_method': payMethod,
      });
      return response['code'] == 0;
    } catch (e) {
      debugPrint('购买VIP失败: $e');
      return false;
    }
  }

  /// 购买音币充值包
  Future<bool> buyCoins(int packageId, {String payMethod = 'alipay'}) async {
    try {
      final response = await _api.post('/membership/buy-coins', data: {
        'package_id': packageId,
        'pay_method': payMethod,
      });
      return response['code'] == 0;
    } catch (e) {
      debugPrint('购买音币失败: $e');
      return false;
    }
  }

  /// 每日签到
  Future<Map<String, dynamic>?> checkIn() async {
    try {
      final response = await _api.post('/membership/check-in');
      if (response['code'] == 0) {
        return Map<String, dynamic>.from(response['data'] ?? {});
      }
      return null;
    } catch (e) {
      debugPrint('签到失败: $e');
      return null;
    }
  }

  /// 获取AI创作配额信息（今日使用次数/上限、音币余额）
  Future<Map<String, dynamic>?> getAIQuota() async {
    try {
      final response = await _api.get('/membership/ai-quota');
      if (response['code'] == 0) {
        return Map<String, dynamic>.from(response['data'] ?? {});
      }
      return null;
    } catch (e) {
      debugPrint('获取AI配额失败: $e');
      return null;
    }
  }

  /// 获取音币收支记录
  Future<Map<String, dynamic>> getCoinRecords({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _api.get(
        '/membership/coin-records',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      if (response['code'] == 0) {
        final data = response['data'] ?? {};
        return {
          'records': List<Map<String, dynamic>>.from(data['records'] ?? []),
          'total': data['total'] ?? 0,
        };
      }
      return {'records': <Map<String, dynamic>>[], 'total': 0};
    } catch (e) {
      debugPrint('获取音币记录失败: $e');
      return {'records': <Map<String, dynamic>>[], 'total': 0};
    }
  }
}
