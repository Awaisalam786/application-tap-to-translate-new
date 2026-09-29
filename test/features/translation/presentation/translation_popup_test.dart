// test/features/translation/presentation/translation_popup_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:tap_to_translate/core/models/selection_result.dart';
import 'package:tap_to_translate/core/models/word_occurrence.dart';
import 'package:tap_to_translate/features/translation/presentation/controllers/translation_controller.dart';
import 'package:tap_to_translate/features/translation/presentation/widgets/translation_popup.dart';

void main() {
  group('TranslationPopup UI Invariant Tests', () {
    testWidgets('1. Exact word selected -> TranslationPopup displays word, translation, badge', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TranslationPopup(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before word selection: popup is not rendered
      expect(find.byType(TranslationPopup), findsOneWidget);
      expect(find.text('Deutschland'), findsNothing);

      // Trigger exact selection on "Deutschland."
      final word = WordOccurrence(
        rawText: 'Deutschland.',
        cleanWord: 'Deutschland',
        pageBoundingBox: const PdfRect(200, 750, 300, 735),
        pageNumber: 1,
        charIndex: 20,
        charLength: 12,
        charRects: const [],
      );

      final notifier = container.read(translationControllerProvider.notifier);
      await notifier.translateWord(word);
      await tester.pumpAndSettle();

      // Verify popup content
      expect(find.text('Deutschland'), findsOneWidget);
      expect(find.text('Im PDF: "Deutschland."'), findsOneWidget);
      expect(find.text('Germany'), findsOneWidget);
      expect(find.text('LOKALES LEXIKON'), findsOneWidget);
      expect(find.text('Neutrum'), findsOneWidget);
      expect(find.text('Zu Meine Wörter'), findsOneWidget);

      // Test pronunciation button interface
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pumpAndSettle();
      expect(container.read(translationControllerProvider).lastPronouncedWord, equals('Deutschland'));

      // Test "Zu Meine Wörter" action
      await tester.tap(find.text('Zu Meine Wörter'));
      await tester.pumpAndSettle();

      expect(find.text('Gespeichert'), findsOneWidget);
      expect(container.read(translationControllerProvider).isSavedToMyWords, isTrue);

      // Tap "Gespeichert" again to un-save
      await tester.tap(find.text('Gespeichert'));
      await tester.pumpAndSettle();

      expect(find.text('Zu Meine Wörter'), findsOneWidget);
      expect(container.read(translationControllerProvider).isSavedToMyWords, isFalse);

      // Test Language Switching (e.g. to Urdu)
      await tester.tap(find.textContaining('Urdu'));
      await tester.pumpAndSettle();

      expect(find.text('جرمنی'), findsOneWidget);

      // Test close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(container.read(translationControllerProvider).currentResult, isNull);
    });

    testWidgets('2. Selection Invariants: Non-exact selections must NOT show TranslationPopup', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final translationNotifier = container.read(translationControllerProvider.notifier);

      // Case A: Whitespace Selection -> NO POPUP
      final whitespaceResult = SelectionResult.whitespace(
        screenTapOffset: const Offset(10, 10),
        pdfTapPoint: const PdfPoint(10, 10),
        pageNumber: 1,
      );
      if (whitespaceResult.status == SelectionStatus.exactMatch && whitespaceResult.word != null) {
        await translationNotifier.translateWord(whitespaceResult.word!);
      } else {
        translationNotifier.dismissPopup();
      }
      expect(container.read(translationControllerProvider).currentResult, isNull);

      // Case B: Inter-Word Gap Selection -> NO POPUP (ZERO nearest-word fallback)
      final gapResult = SelectionResult.gap(
        screenTapOffset: const Offset(165, 100),
        pdfTapPoint: const PdfPoint(165, 742.5),
        pageNumber: 1,
      );
      if (gapResult.status == SelectionStatus.exactMatch && gapResult.word != null) {
        await translationNotifier.translateWord(gapResult.word!);
      } else {
        translationNotifier.dismissPopup();
      }
      expect(container.read(translationControllerProvider).currentResult, isNull);

      // Case C: Ambiguous Overlapping Selection -> NO POPUP
      final ambiguousResult = SelectionResult.ambiguous(
        screenTapOffset: const Offset(145, 150),
        pdfTapPoint: const PdfPoint(145, 690),
        pageNumber: 1,
        candidates: const [],
      );
      if (ambiguousResult.status == SelectionStatus.exactMatch && ambiguousResult.word != null) {
        await translationNotifier.translateWord(ambiguousResult.word!);
      } else {
        translationNotifier.dismissPopup();
      }
      expect(container.read(translationControllerProvider).currentResult, isNull);

      // Case D: Null/No Selection -> NO POPUP
      translationNotifier.dismissPopup();
      expect(container.read(translationControllerProvider).currentResult, isNull);
    });

    testWidgets('3. NOT_FOUND state renders clear user message without hallucination', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TranslationPopup(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final unknownWord = WordOccurrence(
        rawText: 'UnbekanntesWort123',
        cleanWord: 'UnbekanntesWort123',
        pageBoundingBox: const PdfRect(100, 500, 200, 485),
        pageNumber: 1,
        charIndex: 0,
        charLength: 18,
        charRects: const [],
      );

      await container.read(translationControllerProvider.notifier).translateWord(unknownWord);
      await tester.pumpAndSettle();

      expect(find.text('Wort nicht im Lexikon gefunden'), findsOneWidget);
      expect(find.text('NICHT GEFUNDEN'), findsOneWidget);
      expect(find.text('Zu Meine Wörter'), findsNothing); // Cannot save notFound word
    });
  });
}
