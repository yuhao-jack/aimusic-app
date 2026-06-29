import 'package:get/get.dart';
import 'package:aimusic_app/modules/voice_clone/voice_clone_controller.dart';

class VoiceCloneBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VoiceCloneController>(() => VoiceCloneController());
  }
}
