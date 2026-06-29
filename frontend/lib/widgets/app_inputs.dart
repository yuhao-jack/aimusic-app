import 'package:flutter/material.dart';
import 'package:aimusic_app/theme/app_theme.dart';

/// 统一的输入组件库
class AppInputs {
  // ===== 基础文本输入 =====
  static Widget text({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
    int? maxLines = 1,
    int? minLines,
    bool enabled = true,
    bool expands = false,
    bool readOnly = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    String? errorText,
    EdgeInsets? contentPadding,
    TextStyle? style,
    TextStyle? labelStyle,
    TextStyle? hintStyle,
  }) {
    final textStyle = style ??
        const TextStyle(
          color: AppTheme.textWhite,
          fontSize: 16,
        );

    final labelTextStyle = labelStyle ??
        const TextStyle(
          color: AppTheme.textLightGray,
          fontSize: 14,
        );

    final hintTextStyle = hintStyle ??
        const TextStyle(
          color: AppTheme.textLightGray,
          fontSize: 14,
        );

    final effectiveContentPadding = contentPadding ??
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      expands: expands,
      readOnly: readOnly,
      textCapitalization: textCapitalization,
      autovalidateMode: autovalidateMode,
      validator: validator,
      focusNode: focusNode,
      style: textStyle,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.midDark,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: AppTheme.textLightGray,
              )
            : null,
        suffixIcon: suffixIcon,
        labelText: label,
        labelStyle: labelTextStyle,
        hintText: hint,
        hintStyle: hintTextStyle,
        errorText: errorText,
        contentPadding: effectiveContentPadding,
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
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: const BorderSide(
            color: AppTheme.errorColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusComfortable),
          borderSide: const BorderSide(
            color: AppTheme.errorColor,
            width: 1,
          ),
        ),
      ),
    );
  }

  // ===== 密码输入 =====
  static Widget password({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    String? hint,
    TextInputAction textInputAction = TextInputAction.done,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
    String? errorText,
    String? Function(String?)? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) {
    return text(
      controller: controller,
      label: label,
      hint: hint,
      obscureText: obscureText,
      prefixIcon: Icons.lock_outline,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      enabled: enabled,
      errorText: errorText,
      validator: validator,
      autovalidateMode: autovalidateMode,
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppTheme.textLightGray,
        ),
        onPressed: onToggleObscure,
      ),
    );
  }

  // ===== 邮箱输入 =====
  static Widget email({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
    String? errorText,
    String? Function(String?)? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) {
    return text(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      enabled: enabled,
      errorText: errorText,
      validator: validator,
      autovalidateMode: autovalidateMode,
    );
  }

  // ===== 手机号输入 =====
  static Widget phone({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
    String? errorText,
    String? Function(String?)? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) {
    return text(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      enabled: enabled,
      errorText: errorText,
      validator: validator,
      autovalidateMode: autovalidateMode,
    );
  }

  // ===== 搜索输入 =====
  static Widget search({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
    VoidCallback? onClear,
    bool enabled = true,
    bool readOnly = false,
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.midDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusFullPill),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        enabled: enabled,
        readOnly: readOnly,
        focusNode: focusNode,
        style: const TextStyle(
          color: AppTheme.textWhite,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppTheme.textLightGray,
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppTheme.textLightGray,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.textLightGray,
                    size: 20,
                  ),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ===== 多行文本输入 =====
  static Widget multiline({
    required TextEditingController controller,
    required String label,
    String? hint,
    int minLines = 4,
    int maxLines = 10,
    TextInputAction textInputAction = TextInputAction.newline,
    ValueChanged<String>? onChanged,
    bool enabled = true,
    String? errorText,
    String? Function(String?)? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) {
    return text(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      minLines: minLines,
      textInputAction: textInputAction,
      keyboardType: TextInputType.multiline,
      onChanged: onChanged,
      enabled: enabled,
      errorText: errorText,
      validator: validator,
      autovalidateMode: autovalidateMode,
    );
  }
}
