import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';
import 'package:nexobank_mobile/features/transactions/domain/models/transaction.dart';

class TransactionItemWidget extends StatelessWidget {
  const TransactionItemWidget({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final formattedAmount = NumberFormat.currency(locale: 'es_MX', symbol: 'MXN ')
        .format(Decimal.parse(transaction.amount).toDouble());

    final rawDate = DateTime.tryParse(transaction.createdAt);
    final formattedDate = rawDate != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(rawDate.toLocal())
        : transaction.createdAt;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isCredit ? Colors.green.shade100 : Colors.red.shade100,
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(formattedDate),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isCredit ? '+' : '-'}$formattedAmount',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
          if (!transaction.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.turquoise.withAlpha(30),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              child: Text(
                transaction.status.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.turquoise,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
