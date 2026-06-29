import 'package:get/get.dart';
import 'package:aimusic_app/modules/follow/follow_controller.dart';

class FollowBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FollowController>(() => FollowController());
  }
}
