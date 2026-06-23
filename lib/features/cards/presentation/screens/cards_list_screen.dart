import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/features/cards/presentation/providers/cards_notifier.dart';
import 'package:nexobank_mobile/features/cards/presentation/widgets/card_widget.dart';

class CardsListScreen extends ConsumerWidget {
  const CardsListScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsState = ref.watch(cardsNotifierProvider(accountId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mis tarjetas')),
      body: cardsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, stackTrace) => const Center(child: Text('No se pudieron cargar las tarjetas')),
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(child: Text('No tienes tarjetas asociadas'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return CardWidget(
                card: card,
                onToggleFreeze: () => ref
                    .read(cardsNotifierProvider(accountId).notifier)
                    .toggleFreeze(card.id),
              );
            },
          );
        },
      ),
    );
  }
}
