import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/spotify_importer/presentation/widgets/universal_import_dialog.dart';

void main() {
  testWidgets('UniversalImportDialog renders input field and header properly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: UniversalImportDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('IMPORT SPOTIFY & YOUTUBE'), findsOneWidget);
    expect(
      find.text('Paste track, album, or playlist links to stream or download'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
  });
}
