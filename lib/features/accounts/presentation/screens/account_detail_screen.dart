import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/features/accounts/presentation/providers/account_detail_notifier.dart';
import 'package:nexobank_mobile/features/accounts/presentation/widgets/balance_display_widget.dart';
import 'package:nexobank_mobile/features/cards/presentation/providers/cards_notifier.dart';
import 'package:nexobank_mobile/features/cards/presentation/widgets/card_widget.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountDetailNotifierProvider(accountId));

    return accountState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) {
        // If unauthorized ownership, navigate away
        if (error.toString().contains('no autorizado')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(AppRoutes.home);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Detalle de cuenta')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('No se pudo cargar la cuenta'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(accountDetailNotifierProvider(accountId).notifier)
                      .build(accountId),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      },
      data: (account) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              account.accountType == 'checking'
                  ? 'Cuenta de Débito'
                  : 'Cuenta de Ahorro',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo disponible',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    BalanceDisplayWidget(
                      balance: account.balance,
                      currency: account.currency,
                    ),
                    const Divider(height: 32),
                    _InfoRow(
                      label: 'Número de cuenta',
                      value: account.accountNumber,
                    ),
                    _InfoRow(label: 'Moneda', value: account.currency),
                    _InfoRow(
                      label: 'Estado',
                      value: account.isActive ? 'Activa' : 'Inactiva',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Mis tarjetas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _CardsSection(accountId: accountId),
              const SizedBox(height: 24),
              Text(
                'Movimientos recientes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              // Placeholder — Agente C (transfers/transactions) fills this
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Historial de transacciones próximamente'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardsSection extends ConsumerWidget {
  const _CardsSection({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsState = ref.watch(cardsNotifierProvider(accountId));

    return cardsState.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, stackTrace) => const Text('No se pudieron cargar las tarjetas'),
      data: (cards) {
        if (cards.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No tienes tarjetas asociadas'),
          );
        }
        return Column(
          children: cards
              .map(
                (card) => CardWidget(
                  card: card,
                  onToggleFreeze: () => ref
                      .read(cardsNotifierProvider(accountId).notifier)
                      .toggleFreeze(card.id),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
