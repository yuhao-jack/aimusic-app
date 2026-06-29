import 'package:get/get.dart';
import 'package:aimusic_app/modules/onboarding/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(OnboardingController());
  }
}
