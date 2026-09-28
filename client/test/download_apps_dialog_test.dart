import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_helpdesk_client/shared/widgets/download_apps_dialog.dart';

void main() {
  testWidgets('DownloadAppsDialog renders Windows and Android download cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DownloadAppsDialog(),
        ),
      ),
    );

    // Verify Title & Subtitle
    expect(find.text('Download NexAssist Apps'), findsOneWidget);
    expect(find.text('Install standalone desktop & mobile native clients'), findsOneWidget);

    // Verify Windows Desktop Card
    expect(find.text('Windows Desktop Client'), findsOneWidget);
    expect(find.text('.EXE'), findsOneWidget);
    expect(find.textContaining('NexAssist-Setup.exe'), findsOneWidget);

    // Verify Android Mobile Card
    expect(find.text('Android Mobile Application'), findsOneWidget);
    expect(find.text('.APK'), findsOneWidget);
    expect(find.textContaining('NexAssist-Android.apk'), findsOneWidget);

    // Verify Download Action Buttons
    expect(find.textContaining('Download .EXE'), findsOneWidget);
    expect(find.textContaining('Download .APK'), findsOneWidget);
  });
}
