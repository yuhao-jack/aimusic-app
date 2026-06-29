import 'package:get/get.dart';
import 'package:aimusic_app/modules/search/search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SearchController>(() => SearchController());
  }
}
