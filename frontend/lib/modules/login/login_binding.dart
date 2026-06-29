import 'package:get/get.dart';
import 'package:aimusic_app/modules/login/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
