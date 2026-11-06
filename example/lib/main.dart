import 'dart:async';
import 'dart:io';

import 'package:fload_attribution/fload_attribution.dart';
import 'package:flutter/material.dart';

/// The example only ever talks to the local ingest stub
/// (`node tool/ingest-stub.mjs` in the repo root), never to Fload.
/// The Android emulator reaches the host at 10.0.2.2.
final Uri stubEndpoint = Uri.parse(
  Platform.isAndroid ? 'http://10.0.2.2:3999' : 'http://localhost:3999',
);
const String exampleKey = 'fload_pk_example_local_stub';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FloadAttribution.configure(
    exampleKey,
    endpoint: stubEndpoint,
    logLevel: FloadLogLevel.debug,
  );
  FloadAttribution.setUserId('example-user-1');
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  String? _reference;
  int _userIds = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // The native SDK loads its state in the background, so ask until it has one.
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      final reference = await FloadAttribution.installReference;
      if (reference != null && mounted) {
        timer.cancel();
        setState(() => _reference = reference);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fload Attribution ${FloadAttribution.version}'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text('Sending to $stubEndpoint'),
              Text(
                'Install reference: ${_reference ?? 'loading…'}',
                key: const Key('install-reference'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() => _userIds += 1);
                  FloadAttribution.setUserId('example-user-$_userIds');
                },
                child: const Text('Link another user id'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
