import 'package:get/get.dart';
import 'package:aimusic_app/modules/player/player_controller.dart';

class PlayerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PlayerController());
  }
}
