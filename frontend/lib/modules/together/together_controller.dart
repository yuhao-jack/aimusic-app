import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/services/api_service.dart';
import 'package:aimusic_app/utils/toast_util.dart';

class TogetherController extends GetxController {
  final TextEditingController roomCodeInputController = TextEditingController();
  final TextEditingController roomNameController = TextEditingController();
  final TextEditingController roomPasswordController = TextEditingController();
  final TextEditingController roomDescController = TextEditingController();

  final ApiService _api = Get.find<ApiService>();

  final RxString roomCode = ''.obs;
  final Rx<Map?> currentRoom = Rx<Map?>(null);
  final RxBool needPassword = false.obs;

  // 社区动态列表
  final RxList<Map<String, dynamic>> feedItems = <Map<String, dynamic>>[].obs;
  // 公开房间列表
  final RxList<Map<String, dynamic>> publicRooms = <Map<String, dynamic>>[].obs;
  final RxBool publicRoomsLoading = false.obs;
  // 我的房间列表
  final RxList<Map<String, dynamic>> myRooms = <Map<String, dynamic>>[].obs;
  // 我的房间加载状态
  final RxBool myRoomsLoading = false.obs;
  // 房间成员
  final RxList<Map<String, dynamic>> roomMembers = <Map<String, dynamic>>[].obs;
  // 记录正在加入的房间索引
  final RxInt joiningIndex = (-1).obs;
  // 创建中状态
  final RxBool isCreating = false.obs;
  // 房间信息加载中
  final RxBool isRoomLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFeed();
    fetchMyRooms();
    fetchPublicRooms();
  }

  /// 加载我的房间列表
  Future<void> fetchMyRooms() async {
    myRoomsLoading.value = true;
    try {
      final data = await _api.get('/music/together/my-rooms');
      if (data is Map && data['code'] == 0) {
        final respData = data['data'];
        if (respData is List) {
          myRooms.value = respData.cast<Map<String, dynamic>>();
        } else if (respData is Map && respData['list'] is List) {
          myRooms.value = (respData['list'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      myRooms.value = [];
    } finally {
      myRoomsLoading.value = false;
    }
  }

  @override
  void onClose() {
    roomCodeInputController.dispose();
    roomNameController.dispose();
    roomPasswordController.dispose();
    roomDescController.dispose();
    super.onClose();
  }

  /// 获取社区动态
  Future<void> fetchFeed() async {
    try {
      final data = await _api.get('/music/together/feed');
      if (data is Map && data['code'] == 0) {
        final respData = data['data'];
        if (respData is List) {
          feedItems.value = respData.cast<Map<String, dynamic>>();
        } else if (respData is Map && respData['list'] is List) {
          feedItems.value = (respData['list'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      feedItems.value = [];
    }
  }

  /// 获取公开房间列表
  Future<void> fetchPublicRooms() async {
    publicRoomsLoading.value = true;
    try {
      final data = await _api.get('/music/together/rooms');
      if (data is Map && data['code'] == 0) {
        final respData = data['data'];
        if (respData is List) {
          publicRooms.value = respData.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      publicRooms.value = [];
    } finally {
      publicRoomsLoading.value = false;
    }
  }

  /// 下拉刷新
  Future<void> refreshData() async {
    await Future.wait([fetchFeed(), fetchMyRooms(), fetchPublicRooms()]);
  }

  /// 创建一起听房间
  Future<void> createRoom(int songId) async {
    if (isCreating.value) return;
    isCreating.value = true;
    try {
      final body = <String, dynamic>{
        'song_id': songId,
        'name': roomNameController.text.trim().isNotEmpty
            ? roomNameController.text.trim()
            : '一起听歌',
        'max_members': 10,
      };
      if (roomPasswordController.text.trim().isNotEmpty) {
        body['password'] = roomPasswordController.text.trim();
      }
      if (roomDescController.text.trim().isNotEmpty) {
        body['description'] = roomDescController.text.trim();
      }

      final data = await _api.post('/music/together/create', data: body);
      if (data is Map && data['code'] == 0) {
        final respData = data['data'];
        final newRoomCode = respData['room_code'].toString();
        roomCode.value = newRoomCode;
        currentRoom.value = {
          'room_code': newRoomCode,
          'room_id': respData['room_id'],
          'song_id': songId,
        };
        // 清空输入
        roomCodeInputController.clear();
        roomNameController.clear();
        roomPasswordController.clear();
        roomDescController.clear();
        ToastUtil.showSuccess('房间创建成功！邀请码: $newRoomCode');
      } else {
        final msg = data is Map ? data['msg'] : null;
        ToastUtil.showError(msg ?? '创建房间失败');
      }
    } catch (e) {
      debugPrint('创建房间失败：$e');
      ToastUtil.showError('创建房间失败，请重试');
    } finally {
      isCreating.value = false;
    }
  }

  /// 加入一起听房间
  Future<void> joinRoom(String code, {String? password}) async {
    if (joiningIndex.value >= 0) return;
    joiningIndex.value = 0;
    try {
      final body = <String, dynamic>{};
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final data = await _api.post('/music/together/join/$code', data: body);
      if (data is Map && data['code'] == 0) {
        final respData = data['data'];
        currentRoom.value = respData['room'];
        roomCode.value = code;
        roomCodeInputController.clear();
        ToastUtil.showSuccess('加入房间成功');
      } else {
        final msg = data is Map ? data['msg'] : '加入失败';
        if (msg == '密码错误') {
          needPassword.value = true;
        }
        ToastUtil.showError(msg ?? '加入失败');
      }
    } catch (e) {
      debugPrint('加入房间失败：$e');
      ToastUtil.showError('加入失败，请检查邀请码是否正确');
    } finally {
      joiningIndex.value = -1;
    }
  }

  /// 获取房间详情
  Future<void> loadRoomInfo(int roomId) async {
    isRoomLoading.value = true;
    try {
      final data = await _api.get('/music/together/room/$roomId');
      if (data is Map && data['code'] == 0) {
        final respData = data['data'];
        currentRoom.value = respData['room'];
        if (respData['members'] != null) {
          roomMembers.value = (respData['members'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('加载房间信息失败：$e');
    } finally {
      isRoomLoading.value = false;
    }
  }

  /// 更新房间信息（房主）
  Future<void> updateRoom(int roomId, Map<String, dynamic> body) async {
    try {
      final data = await _api.put('/music/together/room/$roomId', data: body);
      if (data is Map && data['code'] == 0) {
        ToastUtil.showSuccess('更新成功');
        await loadRoomInfo(roomId);
      } else {
        ToastUtil.showError('更新失败');
      }
    } catch (e) {
      ToastUtil.showError('更新失败');
    }
  }

  /// 踢出成员（房主）
  Future<void> kickMember(int roomId, int memberId) async {
    try {
      final data = await _api.post('/music/together/room/$roomId/kick/$memberId');
      if (data is Map && data['code'] == 0) {
        ToastUtil.showSuccess('已踢出');
        await loadRoomInfo(roomId);
      } else {
        ToastUtil.showError('操作失败');
      }
    } catch (e) {
      ToastUtil.showError('操作失败');
    }
  }

  /// 离开房间
  Future<void> leaveRoom() async {
    if (currentRoom.value == null) return;
    final roomId = currentRoom.value!['id'] ?? currentRoom.value!['ID'];
    if (roomId != null) {
      try {
        await _api.post('/music/together/leave/$roomId');
      } catch (e) {
        debugPrint('离开房间失败：$e');
      }
    }
    currentRoom.value = null;
    roomCode.value = '';
    roomMembers.clear();
    fetchMyRooms();
    ToastUtil.showSuccess('已离开房间');
  }
}
