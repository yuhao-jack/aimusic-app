import 'package:get/get.dart';
import 'package:aimusic_app/modules/music/music_detail_controller.dart';

class MusicDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MusicDetailController>(() => MusicDetailController());
  }
}
