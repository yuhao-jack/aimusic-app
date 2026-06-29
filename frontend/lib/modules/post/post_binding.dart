import 'package:get/get.dart';
import 'post_controller.dart';
import 'create_post_controller.dart';

class PostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostController>(() => PostController());
  }
}

class CreatePostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreatePostController>(() => CreatePostController());
  }
}
