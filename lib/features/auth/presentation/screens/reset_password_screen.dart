import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';
import 'package:nexobank_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:nexobank_mobile/features/auth/presentation/widgets/nexo_primary_button.dart';
import 'package:nexobank_mobile/features/auth/presentation/widgets/nexo_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final result = await ref.read(authRepositoryProvider).resetPassword(
          token: _tokenController.text.trim(),
          newPassword: _newPasswordController.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    switch (result) {
      case Success<void>():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña restablecida correctamente')),
        );
        context.go(AppRoutes.login);
      case Failure<void>(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(error)),
            backgroundColor: Colors.red.shade700,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        title: const Text('Nueva contraseña'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NexoTextField(
                  controller: _tokenController,
                  label: 'Código de verificación',
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa el código' : null,
                ),
                const SizedBox(height: 16),
                NexoTextField(
                  controller: _newPasswordController,
                  label: 'Nueva contraseña',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
                ),
                const SizedBox(height: 32),
                NexoPrimaryButton(
                  label: 'Restablecer contraseña',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _errorMessage(AppError err) {
    return switch (err) {
      NetworkError(message: final msg) => 'Sin conexión: $msg',
      UnknownError(message: final msg) => msg,
      _ => 'Código inválido o expirado',
    };
  }
}
