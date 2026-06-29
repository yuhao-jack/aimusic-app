import 'package:get/get.dart';
import 'package:aimusic_app/modules/profile/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
