import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/features/transfers/presentation/providers/transfer_notifier.dart';

class TransferResultScreen extends ConsumerWidget {
  const TransferResultScreen({super.key});

  String _errorMessage(AppError error) => switch (error) {
        InsufficientFundsError() => 'Saldo insuficiente para realizar la transferencia.',
        AccountNotFoundError() => 'Cuenta destino no encontrada.',
        NetworkError(message: final m) => m,
        UnknownError(message: final m) => m,
        _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state is TransferSuccess) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 24),
              const Text(
                '¡Transferencia exitosa!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                NumberFormat.currency(locale: 'es_MX', symbol: 'MXN ').format(
                  Decimal.parse(state.transfer.amount).toDouble(),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
            ] else if (state is TransferFailure) ...[
              const Icon(Icons.cancel, color: Colors.red, size: 72),
              const SizedBox(height: 24),
              const Text(
                'Error en la transferencia',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage(state.error),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ] else ...[
              const CircularProgressIndicator(),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ref.read(transferNotifierProvider.notifier).reset();
                context.go('/transfer');
              },
              child: const Text('Nueva transferencia'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.read(transferNotifierProvider.notifier).reset();
                context.go('/home');
              },
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
