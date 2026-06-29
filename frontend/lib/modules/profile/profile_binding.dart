import 'package:get/get.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // ProfileController已经在main.dart中全局注册，无需再次注册
  }
}
