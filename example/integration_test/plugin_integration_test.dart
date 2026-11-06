// Runs on a simulator or emulator against the local ingest stub:
//   node tool/ingest-stub.mjs   (in the repo root)
//   flutter test integration_test (in example/)
import 'dart:io';

import 'package:fload_attribution/fload_attribution.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the native SDK starts and makes an install reference', (
    tester,
  ) async {
    final endpoint = Uri.parse(
      Platform.isAndroid ? 'http://10.0.2.2:3999' : 'http://localhost:3999',
    );
    await FloadAttribution.configure(
      'fload_pk_example_local_stub',
      endpoint: endpoint,
    );
    await FloadAttribution.setUserId('integration-test-user');

    String? reference;
    for (var attempt = 0; attempt < 40 && reference == null; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      reference = await FloadAttribution.installReference;
    }
    expect(reference, isNotNull);
    expect(reference, matches(RegExp(r'^[A-Za-z0-9._:-]{8,128}$')));
  });
}
