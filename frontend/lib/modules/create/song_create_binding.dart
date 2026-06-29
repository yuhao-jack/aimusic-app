import 'package:get/get.dart';
import 'package:aimusic_app/modules/create/song_create_controller.dart';

class SongCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SongCreateController>(() => SongCreateController());
  }
}
