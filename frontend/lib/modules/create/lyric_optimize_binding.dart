import 'package:get/get.dart';
import 'lyric_optimize_controller.dart';

class LyricOptimizeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LyricOptimizeController>(
      () => LyricOptimizeController(),
    );
  }
}
