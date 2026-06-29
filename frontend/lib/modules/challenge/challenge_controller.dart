import 'package:get/get.dart';
import 'package:aimusic_app/utils/http_util.dart';

class ChallengeController extends GetxController {
  final RxList challengeList = [].obs;
  final RxMap hotChallenge = {}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChallenges();
  }

  Future<void> fetchChallenges() async {
    isLoading.value = true;
    try {
      final response = await HttpUtil().get('/challenges');
      if (response.statusCode == 200 && response.data['code'] == 0) {
        final data = response.data['data'] ?? {};
        hotChallenge.value = data['hot'] ?? {};
        challengeList.value = data['list'] ?? [];
      }
    } catch (e) {
      // 静默失败，显示空状态
    } finally {
      isLoading.value = false;
    }
  }
}
