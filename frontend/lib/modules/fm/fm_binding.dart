import 'package:get/get.dart';
import 'package:aimusic_app/modules/fm/fm_controller.dart';

/// 私人FM模块绑定
class FmBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FmController());
  }
}