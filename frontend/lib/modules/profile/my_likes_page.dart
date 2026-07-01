import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/profile/my_likes_controller.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

class MyLikesPage extends GetView<MyLikesController> {
  MyLikesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Text(
          '我的喜欢',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return PageShimmer(itemCount: 6);
        }

        if (controller.likes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 80,
                  color: AppTheme.textDarkGray,
                ),
                SizedBox(height: 24),
                Text(
                  '还没有喜欢的音乐',
                  style: TextStyle(
                    color: AppTheme.textSilver,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '去首页浏览音乐，喜欢的可以点赞收藏',
                  style: TextStyle(
                    color: AppTheme.textDarkGray,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: controller.likes.length,
          itemBuilder: (context, index) {
            final item = controller.likes[index];
            final music = item['music'];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: music['cover'] != null && music['cover'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          music['cover'],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.surface3,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.music_note, color: AppTheme.textDarkGray),
                      ),
                title: Text(
                  music['title'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                subtitle: Text(
                  music['artist'] ?? music['singer'] ?? '',
                  style: TextStyle(
                    color: AppTheme.textLightGray,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textLightGray,
                ),
                onTap: () {
                  Get.toNamed(AppRoutes.musicDetail, arguments: music['id']);
                },
              ),
            );
          },
        );
      }),
    );
  }
}
