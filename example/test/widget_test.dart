import 'package:fload_attribution/fload_attribution.dart';
import 'package:fload_attribution_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the install reference once the SDK has one', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      FloadAttribution.channel,
      (call) async =>
          call.method == 'getInstallReference' ? 'd462359f-reference' : null,
    );
    await tester.pumpWidget(const ExampleApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Install reference: d462359f-reference'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
