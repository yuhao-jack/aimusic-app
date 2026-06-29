import 'package:get/get.dart';
import 'package:aimusic_app/modules/report/listening_report_controller.dart';

class ListeningReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListeningReportController>(() => ListeningReportController());
  }
}
