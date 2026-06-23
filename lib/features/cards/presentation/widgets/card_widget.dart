import 'package:flutter/material.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';
import 'package:nexobank_mobile/features/cards/domain/models/card_model.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.card,
    required this.onToggleFreeze,
  });

  final CardModel card;
  final VoidCallback onToggleFreeze;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandDeep, AppColors.brand],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.cardType == 'credit' ? 'CRÉDITO' : 'DÉBITO',
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                _StatusBadge(isFrozen: card.isFrozen),
              ],
            ),
            const Spacer(),
            Text(
              card.maskedNumber,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VENCE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      card.expiryDate,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                _FreezeButton(
                  isFrozen: card.isFrozen,
                  onTap: () => _confirmToggle(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmToggle(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(card.isFrozen ? 'Descongelar tarjeta' : 'Congelar tarjeta'),
        content: Text(
          card.isFrozen
              ? '¿Deseas activar esta tarjeta nuevamente?'
              : '¿Deseas congelar esta tarjeta? No podrá usarse hasta que la descongeles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onToggleFreeze();
            },
            child: Text(card.isFrozen ? 'Descongelar' : 'Congelar'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isFrozen});

  final bool isFrozen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFrozen
            ? Colors.grey.shade600
            : AppColors.turquoise.withValues(alpha: 0.25),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFrozen)
            const Icon(Icons.lock, color: Colors.white, size: 12),
          if (isFrozen) const SizedBox(width: 4),
          Text(
            isFrozen ? 'CONGELADA' : 'ACTIVA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreezeButton extends StatelessWidget {
  const _FreezeButton({required this.isFrozen, required this.onTap});

  final bool isFrozen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isFrozen ? 'Descongelar tarjeta' : 'Congelar tarjeta',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFrozen ? Icons.lock_open : Icons.lock,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                isFrozen ? 'Descongelar' : 'Congelar',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
