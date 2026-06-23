import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexobank_mobile/features/transfers/presentation/providers/transfer_notifier.dart';
import 'package:nexobank_mobile/features/transfers/presentation/widgets/amount_input_widget.dart';

class TransferFormData {
  const TransferFormData({
    required this.originAccountId,
    required this.destinationAccountId,
    required this.amount,
    this.description,
  });

  final String originAccountId;
  final String destinationAccountId;
  final String amount;
  final String? description;
}

class TransferFormScreen extends ConsumerStatefulWidget {
  const TransferFormScreen({super.key});

  @override
  ConsumerState<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends ConsumerState<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Placeholder origin account — feature/accounts-cards will expose a provider
  // with real accounts. Hardcoded for now.
  final String _originAccountId = 'my-account-id';

  @override
  void dispose() {
    _amountController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(transferNotifierProvider.notifier).reset();
    context.push(
      '/transfer/confirm',
      extra: TransferFormData(
        originAccountId: _originAccountId,
        destinationAccountId: _destinationController.text.trim(),
        amount: _amountController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva transferencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmountInputWidget(controller: _amountController),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Cuenta destino',
                  hintText: 'Número de cuenta',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa la cuenta destino' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
