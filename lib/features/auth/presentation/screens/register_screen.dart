import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';
import 'package:nexobank_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:nexobank_mobile/features/auth/presentation/widgets/nexo_primary_button.dart';
import 'package:nexobank_mobile/features/auth/presentation/widgets/nexo_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).register(
          name: _nameController.text.trim(),
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

    final isLoading = ref.watch(authNotifierProvider) is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NexoTextField(
                  controller: _nameController,
                  label: 'Nombre completo',
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),
                NexoTextField(
                  controller: _emailController,
                  label: 'Correo electrónico',
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
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
                ),
                const SizedBox(height: 16),
                NexoTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar contraseña',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  validator: (v) => v != _passwordController.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
                const SizedBox(height: 32),
                NexoPrimaryButton(
                  label: 'Registrarme',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
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
      UnauthorizedError() => 'Ya existe una cuenta con ese correo',
      NetworkError(message: final msg) => 'Sin conexión: $msg',
      UnknownError(message: final msg) => msg,
      _ => 'Ocurrió un error inesperado',
    };
  }
}
