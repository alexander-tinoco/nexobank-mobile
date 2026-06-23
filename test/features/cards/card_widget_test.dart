import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexobank_mobile/features/cards/domain/models/card_model.dart';
import 'package:nexobank_mobile/features/cards/presentation/widgets/card_widget.dart';

const _activeCard = CardModel(
  id: 'card1',
  cardNumber: '1234567890123456',
  cardType: 'debit',
  status: 'active',
  expiryDate: '12/28',
  accountId: 'acc1',
);

const _frozenCard = CardModel(
  id: 'card2',
  cardNumber: '9876543210987654',
  cardType: 'credit',
  status: 'frozen',
  expiryDate: '06/26',
  accountId: 'acc1',
);

Widget buildWidget(CardModel card, {VoidCallback? onToggle}) {
  return MaterialApp(
    home: Scaffold(
      body: CardWidget(
        card: card,
        onToggleFreeze: onToggle ?? () {},
      ),
    ),
  );
}

void main() {
  group('CardWidget', () {
    testWidgets('shows ACTIVA badge when card is active', (tester) async {
      await tester.pumpWidget(buildWidget(_activeCard));
      expect(find.text('ACTIVA'), findsOneWidget);
      expect(find.text('CONGELADA'), findsNothing);
    });

    testWidgets('shows CONGELADA badge when card is frozen', (tester) async {
      await tester.pumpWidget(buildWidget(_frozenCard));
      expect(find.text('CONGELADA'), findsOneWidget);
      expect(find.text('ACTIVA'), findsNothing);
    });

    testWidgets('shows masked card number', (tester) async {
      await tester.pumpWidget(buildWidget(_activeCard));
      expect(find.text('**** **** **** 3456'), findsOneWidget);
    });

    testWidgets('tapping freeze button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildWidget(_activeCard));

      await tester.tap(find.text('Congelar'));
      await tester.pumpAndSettle();

      expect(find.text('Congelar tarjeta'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('tapping cancel in dialog does not call onToggleFreeze',
        (tester) async {
      var called = false;
      await tester.pumpWidget(buildWidget(_activeCard, onToggle: () {
        called = true;
      }));

      await tester.tap(find.text('Congelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('confirming freeze calls onToggleFreeze', (tester) async {
      var called = false;
      await tester.pumpWidget(buildWidget(_activeCard, onToggle: () {
        called = true;
      }));

      await tester.tap(find.text('Congelar'));
      await tester.pumpAndSettle();
      // There are two "Congelar" texts: the button and the dialog confirm button
      // The dialog's ElevatedButton text is the last one
      await tester.tap(find.text('Congelar').last);
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });
}
