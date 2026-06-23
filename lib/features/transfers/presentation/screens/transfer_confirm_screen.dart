import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nexobank_mobile/features/transfers/data/dtos/transfer_request_dto.dart';
import 'package:nexobank_mobile/features/transfers/presentation/providers/transfer_notifier.dart';
import 'package:nexobank_mobile/features/transfers/presentation/screens/transfer_form_screen.dart';
import 'package:uuid/uuid.dart';

class TransferConfirmScreen extends ConsumerStatefulWidget {
  const TransferConfirmScreen({super.key, required this.formData});

  final TransferFormData formData;

  @override
  ConsumerState<TransferConfirmScreen> createState() =>
      _TransferConfirmScreenState();
}

class _TransferConfirmScreenState extends ConsumerState<TransferConfirmScreen> {
  // idempotency_key is generated when the screen is entered, NOT when the
  // button is pressed — prevents key reuse across separate attempts.
  late final String _idempotencyKey = const Uuid().v4();

  String get _formattedAmount {
    final decimal = Decimal.parse(widget.formData.amount);
    return NumberFormat.currency(locale: 'es_MX', symbol: 'MXN ')
        .format(decimal.toDouble());
  }

  @override
  void initState() {
    super.initState();
    // Listen for state changes after the frame so we can navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(transferNotifierProvider, (_, next) {
        if (next is TransferSuccess || next is TransferFailure) {
          if (mounted) context.go('/transfer/result');
        }
      });
    });
  }

  void _confirm() {
    final dto = TransferRequestDto(
      amount: widget.formData.amount,
      destinationAccountId: widget.formData.destinationAccountId,
      idempotencyKey: _idempotencyKey,
      description: widget.formData.description,
    );
    ref.read(transferNotifierProvider.notifier).execute(dto);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transferNotifierProvider);
    final isLoading = state is TransferLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar transferencia')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _Row(label: 'Monto', value: _formattedAmount),
                    const SizedBox(height: 8),
                    _Row(
                      label: 'Cuenta destino',
                      value: widget.formData.destinationAccountId,
                    ),
                    if (widget.formData.description != null) ...[
                      const SizedBox(height: 8),
                      _Row(
                        label: 'Descripción',
                        value: widget.formData.description!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: isLoading ? null : _confirm,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirmar envío'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isLoading ? null : () => context.pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
