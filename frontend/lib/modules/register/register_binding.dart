import 'package:get/get.dart';
import 'package:aimusic_app/modules/register/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterController>(() => RegisterController());
  }
}
