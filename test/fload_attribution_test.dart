import 'dart:io';

import 'package:fload_attribution/fload_attribution.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(FloadAttribution.channel, (call) async {
      calls.add(call);
      return call.method == 'getInstallReference' ? '7d1e2f60-reference' : null;
    });
  });

  tearDown(
      () => messenger.setMockMethodCallHandler(FloadAttribution.channel, null));

  /// The `version:` line of a file in this package.
  String versionIn(String path, RegExp pattern) =>
      pattern.firstMatch(File(path).readAsStringSync())!.group(1)!;

  final pubspecVersion =
      versionIn('pubspec.yaml', RegExp(r'^version:\s*(\S+)', multiLine: true));

  test('configure sends the key, no endpoint and the warning level by default',
      () async {
    await FloadAttribution.configure('fload_pk_test');
    expect(calls.single.method, 'configure');
    expect(calls.single.arguments, {
      'key': 'fload_pk_test',
      'endpoint': null,
      'logLevel': 'warning',
      'wrapperName': 'flutter',
      'wrapperVersion': pubspecVersion,
    });
  });

  test('configure names this wrapper and its pubspec version (FLO-3957)',
      () async {
    await FloadAttribution.configure('fload_pk_test');
    final arguments = calls.single.arguments as Map<Object?, Object?>;
    expect(arguments['wrapperName'], 'flutter');
    expect(arguments['wrapperVersion'], pubspecVersion);
  });

  test('every copy of the version is the pubspec version', () {
    expect(FloadAttribution.version, pubspecVersion);
    expect(
        versionIn('ios/fload_attribution.podspec',
            RegExp(r"s\.version\s*=\s*'([^']+)'")),
        pubspecVersion);
    expect(
        versionIn('android/build.gradle.kts',
            RegExp(r'^version\s*=\s*"([^"]+)"', multiLine: true)),
        pubspecVersion);
  });

  test('configure sends the endpoint and level it is given', () async {
    await FloadAttribution.configure(
      'fload_pk_test',
      endpoint: Uri.parse('http://10.0.2.2:3999'),
      logLevel: FloadLogLevel.debug,
    );
    expect(calls.single.arguments, {
      'key': 'fload_pk_test',
      'endpoint': 'http://10.0.2.2:3999',
      'logLevel': 'debug',
      'wrapperName': 'flutter',
      'wrapperVersion': pubspecVersion,
    });
  });

  test('setUserId sends the id', () async {
    await FloadAttribution.setUserId(r'$RCAnonymousID:abc');
    expect(calls.single.method, 'setUserId');
    expect(calls.single.arguments, {'userId': r'$RCAnonymousID:abc'});
  });

  test('installReference returns what the native SDK holds', () async {
    expect(await FloadAttribution.installReference, '7d1e2f60-reference');
  });

  test('without a native half, every call is a quiet no-op', () async {
    messenger.setMockMethodCallHandler(FloadAttribution.channel, null);
    await FloadAttribution.configure('fload_pk_test');
    await FloadAttribution.setUserId('user_1');
    expect(await FloadAttribution.installReference, isNull);
  });

  test('a native error reaches the caller', () async {
    messenger.setMockMethodCallHandler(FloadAttribution.channel, (call) async {
      throw PlatformException(code: 'bad_arguments');
    });
    expect(FloadAttribution.setUserId('user_1'),
        throwsA(isA<PlatformException>()));
  });
}
