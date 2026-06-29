import 'package:get/get.dart';

class CreateBinding extends Bindings {
  @override
  void dependencies() {
    // CreateController已经在main.dart中全局注册，无需再次注册
  }
}
