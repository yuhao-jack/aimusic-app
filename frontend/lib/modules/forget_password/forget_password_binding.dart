import 'package:get/get.dart';
import 'package:aimusic_app/modules/forget_password/forget_password_controller.dart';

class ForgetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgetPasswordController>(() => ForgetPasswordController());
  }
}
