import 'package:flutter_test/flutter_test.dart';
import 'package:kizart/src/app.dart';
import 'package:kizart/src/data/art_repository.dart';
import 'package:kizart/src/state/art_library.dart';

void main() {
  testWidgets('shows private artwork onboarding for an empty library', (
    tester,
  ) async {
    final library = ArtLibrary(ArtRepository());
    await tester.pumpWidget(KizartApp(library: library));

    expect(find.text('Kizart'), findsOneWidget);
    expect(find.text('Every masterpiece has a story'), findsOneWidget);
    expect(find.text('Add a child'), findsOneWidget);
    expect(find.text('Scan art'), findsOneWidget);
  });
}
