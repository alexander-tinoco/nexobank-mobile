import 'package:flutter/material.dart';

// Placeholder — feature/accounts-cards will provide the real accounts list.
// This widget accepts a list of account IDs and labels for selection.
class AccountSelectorWidget extends StatelessWidget {
  const AccountSelectorWidget({
    super.key,
    required this.label,
    required this.accounts,
    required this.selectedAccountId,
    required this.onChanged,
  });

  final String label;
  final List<({String id, String label})> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      initialValue: selectedAccountId,
      items: accounts
          .map(
            (a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona una cuenta' : null,
    );
  }
}
