import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/modules/profile/my_works_controller.dart';
import 'package:aimusic_app/routes/app_routes.dart';
import 'package:aimusic_app/theme/app_theme.dart';
import 'package:aimusic_app/widgets/shimmer_loading.dart';

class MyWorksPage extends GetView<MyWorksController> {
  MyWorksPage({super.key});

  String _getStatusText(String status) {
    switch(status) {
      case 'completed':
        return '已完成';
      case 'processing':
        return '生成中';
      case 'failed':
        return '生成失败';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch(status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      default:
        return AppTheme.textDarkGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface1,
      appBar: AppBar(
        title: Text(
          '我的作品',
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

        if (controller.works.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.queue_music_outlined,
                  size: 80,
                  color: AppTheme.textDarkGray,
                ),
                SizedBox(height: 24),
                Text(
                  '还没有作品',
                  style: TextStyle(
                    color: AppTheme.textSilver,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '去AI创作页生成你的第一首歌吧',
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
          itemCount: controller.works.length,
          itemBuilder: (context, index) {
            final work = controller.works[index];
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
                leading: work['cover'] != null && work['cover'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          work['cover'],
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
                  work['title'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                subtitle: work['status'] != null && work['status'].toString().isNotEmpty
                    ? Container(
                        margin: EdgeInsets.only(top: 4),
                        child: Text(
                          _getStatusText(work['status']),
                          style: TextStyle(
                            color: _getStatusColor(work['status']),
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textLightGray,
                ),
                onTap: () {
                  if (work['music_id'] != null) {
                    Get.toNamed(AppRoutes.musicDetail, arguments: work['music_id']);
                  }
                },
              ),
            );
          },
        );
      }),
    );
  }
}
