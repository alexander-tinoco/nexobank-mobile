import 'package:flutter/material.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(child: _NexoBrandLogo()),
    );
  }
}

class _NexoBrandLogo extends StatelessWidget {
  const _NexoBrandLogo();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
      child: const Text(
        'N',
        style: TextStyle(
          fontSize: 96,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
