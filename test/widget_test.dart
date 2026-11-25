
import 'package:flutter_test/flutter_test.dart';
import 'package:bose_music_player/main.dart';

void main() {
  testWidgets('Bose Music Player launches', (WidgetTester tester) async {
    await tester.pumpWidget(const BoseMusicApp());
    await tester.pump();

    expect(find.text('BOSE'), findsOneWidget);
  });
}
