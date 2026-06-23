import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceDisplayWidget extends StatelessWidget {
  const BalanceDisplayWidget({
    super.key,
    required this.balance,
    required this.currency,
  });

  final String balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final formatted = _format(balance, currency);
    return Text(
      formatted,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  static String _format(String balance, String currency) {
    final decimal = Decimal.parse(balance);
    final symbol = currency == 'MXN' ? 'MXN ' : '$currency ';
    return NumberFormat.currency(locale: 'es_MX', symbol: symbol)
        .format(decimal.toDouble());
  }
}
