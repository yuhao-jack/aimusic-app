import 'package:get/get.dart';
import 'package:aimusic_app/modules/ai_chat/ai_chat_controller.dart';

class AiChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiChatController>(() => AiChatController());
  }
}
