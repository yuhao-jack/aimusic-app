import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimusic_app/theme/app_theme.dart';

class DialogUtil {
  // 确认对话框
  static Future<bool?> showConfirm({
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Content
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSilver,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (onCancel != null) {
                          onCancel();
                        }
                        Get.back(result: false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSilver,
                        side: const BorderSide(color: AppTheme.borderGray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (onConfirm != null) {
                          onConfirm();
                        }
                        Get.back(result: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: AppTheme.elevationNone,
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // 警告对话框
  static Future<bool?> showWarning({
    required String title,
    required String content,
    String confirmText = '确定',
    VoidCallback? onConfirm,
  }) {
    return Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 32,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSilver,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (onConfirm != null) {
                      onConfirm();
                    }
                    Get.back(result: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                    foregroundColor: AppTheme.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: AppTheme.elevationNone,
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // 成功对话框
  static Future<void> showSuccess({
    required String title,
    required String content,
    String confirmText = '确定',
    VoidCallback? onConfirm,
  }) {
    return Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 32,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSilver,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (onConfirm != null) {
                      onConfirm();
                    }
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: AppTheme.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: AppTheme.elevationNone,
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // 错误对话框
  static Future<void> showError({
    required String title,
    required String content,
    String confirmText = '确定',
    VoidCallback? onConfirm,
  }) {
    return Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSilver,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (onConfirm != null) {
                      onConfirm();
                    }
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: AppTheme.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: AppTheme.elevationNone,
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // 加载对话框
  static void showLoading({
    String message = '加载中...',
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSilver,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // 隐藏加载对话框
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // 输入对话框
  static Future<String?> showInput({
    required String title,
    required String hint,
    String confirmText = '确定',
    String cancelText = '取消',
    String initialValue = '',
    TextInputType keyboardType = TextInputType.text,
  }) {
    final TextEditingController controller = TextEditingController(text: initialValue);
    return Get.dialog<String>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Input
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: AppTheme.textDarkGray,
                  ),
                  filled: true,
                  fillColor: AppTheme.midDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back(result: null);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSilver,
                        side: const BorderSide(color: AppTheme.borderGray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(result: controller.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: AppTheme.elevationNone,
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
