import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';
import 'package:nexobank_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:nexobank_mobile/features/auth/presentation/widgets/nexo_primary_button.dart';
import 'package:nexobank_mobile/features/auth/presentation/widgets/nexo_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(authNotifierProvider, (_, next) {
      if (next is AsyncError) {
        final msg = _errorMessage(next.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
        );
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _NexoBrandLogo(),
                const SizedBox(height: 48),
                NexoTextField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  hint: 'usuario@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa tu correo' : null,
                ),
                const SizedBox(height: 16),
                NexoTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                ),
                const SizedBox(height: 32),
                NexoPrimaryButton(
                  label: 'Iniciar sesión',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      isLoading ? null : () => context.push(AppRoutes.forgotPassword),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: AppColors.brand),
                  ),
                ),
                TextButton(
                  onPressed:
                      isLoading ? null : () => context.push(AppRoutes.register),
                  child: const Text(
                    'Crear cuenta',
                    style: TextStyle(color: AppColors.brand),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    return switch (error) {
      UnauthorizedError() => 'Correo o contraseña incorrectos',
      NetworkError(message: final msg) => 'Sin conexión: $msg',
      UnknownError(message: final msg) => msg,
      _ => 'Ocurrió un error inesperado',
    };
  }
}

class _NexoBrandLogo extends StatelessWidget {
  const _NexoBrandLogo();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          AppColors.brandGradient.createShader(bounds),
      child: const Text(
        'N',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 80,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
