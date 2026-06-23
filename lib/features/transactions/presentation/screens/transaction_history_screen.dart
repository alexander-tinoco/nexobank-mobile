import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/features/transactions/presentation/providers/transactions_notifier.dart';
import 'package:nexobank_mobile/features/transactions/presentation/widgets/transaction_item_widget.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(transactionsNotifierProvider.notifier)
          .loadInitial(widget.accountId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de movimientos')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(TransactionsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No se pudieron cargar los movimientos.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref
                  .read(transactionsNotifierProvider.notifier)
                  .loadInitial(widget.accountId),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return const Center(child: Text('No hay transacciones aún.'));
    }

    final footerCount = state.isLoadingMore || !state.hasMore ? 1 : 0;
    return ListView.builder(
      controller: _scrollController,
      itemCount: state.transactions.length + footerCount,
      itemBuilder: (context, index) {
        if (index == state.transactions.length) {
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Has llegado al final',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }
        return Column(
          children: [
            TransactionItemWidget(transaction: state.transactions[index]),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}
