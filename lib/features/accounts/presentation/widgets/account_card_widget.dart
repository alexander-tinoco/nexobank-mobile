import 'package:flutter/material.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';
import 'package:nexobank_mobile/features/accounts/domain/models/account.dart';
import 'package:nexobank_mobile/features/accounts/presentation/widgets/balance_display_widget.dart';

class AccountCardWidget extends StatelessWidget {
  const AccountCardWidget({
    super.key,
    required this.account,
    required this.onTap,
  });

  final Account account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isChecking = account.accountType == 'checking';
    final label = isChecking ? 'CUENTA DE DÉBITO' : 'CUENTA DE AHORRO';
    final icon = isChecking ? Icons.account_balance_wallet : Icons.savings;
    final maskedNumber =
        '**** ${account.accountNumber.substring(account.accountNumber.length - 4)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.brandDeep, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.brandDeep,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                  ),
                  const Spacer(),
                  _StatusBadge(isActive: account.isActive),
                ],
              ),
              const SizedBox(height: 16),
              BalanceDisplayWidget(
                balance: account.balance,
                currency: account.currency,
              ),
              const SizedBox(height: 8),
              Text(
                maskedNumber,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.turquoise.withValues(alpha: 0.15)
            : Colors.grey.shade200,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(
        isActive ? 'ACTIVA' : 'INACTIVA',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.turquoise : Colors.grey.shade600,
        ),
      ),
    );
  }
}
