import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountInputWidget extends StatelessWidget {
  const AmountInputWidget({
    super.key,
    required this.controller,
    this.errorText,
  });

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Monto',
        prefixText: 'MXN ',
        errorText: errorText,
        hintText: '0.00',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Ingresa el monto';
        final parsed = double.tryParse(value);
        if (parsed == null || parsed <= 0) return 'Monto inválido';
        return null;
      },
    );
  }
}
