import 'package:get/get.dart';
import 'package:aimusic_app/modules/create/lyric_create_controller.dart';

class LyricCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LyricCreateController>(() => LyricCreateController());
  }
}
