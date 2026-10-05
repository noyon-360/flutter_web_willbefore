import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Shared text field look: rounded outline, laurel border when focused.
InputDecoration appInputDecoration({
  String? hintText,
  String? labelText,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    suffixIcon: suffixIcon,
    hintStyle: const TextStyle(color: AppColors.textSecondaryHintColor),
    border: border(AppColors.borderColor),
    enabledBorder: border(AppColors.borderColor),
    focusedBorder: border(AppColors.primaryLaurel, 2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
