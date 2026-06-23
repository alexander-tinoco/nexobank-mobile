import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';
import 'package:nexobank_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:nexobank_mobile/features/auth/presentation/widgets/nexo_primary_button.dart';
import 'package:nexobank_mobile/features/auth/presentation/widgets/nexo_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final result = await ref
        .read(authRepositoryProvider)
        .forgotPassword(email: _emailController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    switch (result) {
      case Success<void>():
        setState(() => _sent = true);
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
        title: const Text('Recuperar contraseña'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: _sent ? const _SuccessMessage() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
            style: TextStyle(color: AppColors.onPrimary),
          ),
          const SizedBox(height: 24),
          NexoTextField(
            controller: _emailController,
            label: 'Correo electrónico',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa tu correo' : null,
          ),
          const SizedBox(height: 32),
          NexoPrimaryButton(
            label: 'Enviar enlace',
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  String _errorMessage(AppError err) {
    return switch (err) {
      NetworkError(message: final msg) => 'Sin conexión: $msg',
      UnknownError(message: final msg) => msg,
      _ => 'Ocurrió un error inesperado',
    };
  }
}

class _SuccessMessage extends StatelessWidget {
  const _SuccessMessage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_outline, color: AppColors.brand, size: 64),
        SizedBox(height: 16),
        Text(
          'Revisa tu correo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Te enviamos un enlace para restablecer tu contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.onPrimary),
        ),
      ],
    );
  }
}
