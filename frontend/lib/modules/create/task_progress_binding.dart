import 'package:get/get.dart';
import 'package:aimusic_app/modules/create/task_progress_controller.dart';

class TaskProgressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskProgressController>(() => TaskProgressController());
  }
}
