import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/features/cards/domain/models/card_model.dart';
import 'package:nexobank_mobile/features/cards/presentation/providers/cards_notifier.dart';
import 'package:nexobank_mobile/features/cards/presentation/widgets/card_widget.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({
    super.key,
    required this.accountId,
    required this.cardId,
  });

  final String accountId;
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsState = ref.watch(cardsNotifierProvider(accountId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de tarjeta')),
      body: cardsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, stackTrace) =>
            const Center(child: Text('No se pudo cargar la tarjeta')),
        data: (cards) {
          final CardModel? card = cards.where((c) => c.id == cardId).firstOrNull;
          if (card == null) {
            return const Center(child: Text('Tarjeta no encontrada'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CardWidget(
                card: card,
                onToggleFreeze: () => ref
                    .read(cardsNotifierProvider(accountId).notifier)
                    .toggleFreeze(card.id),
              ),
              const SizedBox(height: 24),
              Card(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Row(label: 'Tipo', value: card.cardType == 'credit' ? 'Crédito' : 'Débito'),
                      _Row(label: 'Número', value: card.maskedNumber),
                      _Row(label: 'Vencimiento', value: card.expiryDate),
                      _Row(label: 'Estado', value: card.isFrozen ? 'Congelada' : 'Activa'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
