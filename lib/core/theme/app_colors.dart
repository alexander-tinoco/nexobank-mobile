import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF08102A);
  static const Color brand = Color(0xFF10C4FF);
  static const Color brandDeep = Color(0xFF1E3A8A);
  static const Color turquoise = Color(0xFF00B4D8);
  static const Color surface = Color(0xFFF2F4F7);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandDeep, brand, turquoise],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
