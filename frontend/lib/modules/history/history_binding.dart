import 'package:get/get.dart';
import 'package:aimusic_app/modules/history/history_controller.dart';

class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HistoryController>(() => HistoryController());
  }
}
