import 'package:get/get.dart';
import 'package:aimusic_app/modules/membership/membership_controller.dart';

class MembershipBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MembershipController());
  }
}
