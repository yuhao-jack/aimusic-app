import 'package:get/get.dart';
import 'package:aimusic_app/modules/profile/public_profile_controller.dart';

class PublicProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PublicProfileController>(() => PublicProfileController());
  }
}
