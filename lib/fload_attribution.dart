/// Fload install attribution for Flutter: Apple's AdServices token on iOS,
/// the Play Install Referrer on Android. No IDFA, no GAID, no tracking prompt.
///
/// The plugin is a thin layer over Fload's native SDKs
/// ([iOS](https://github.com/fload-ai/fload-attribution-ios),
/// [Android](https://github.com/fload-ai/fload-attribution-android)); all the
/// work (the install report, the queue, retries) happens there.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the native SDK writes to the system log. It never logs the key, the
/// token, the referrer or a user id.
enum FloadLogLevel { none, error, warning, info, debug }

/// Fload install attribution.
///
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   FloadAttribution.configure('fload_pk_…');
///   runApp(const MyApp());
/// }
///
/// // Optional, for example with RevenueCat's app user id:
/// FloadAttribution.setUserId(await Purchases.appUserID);
/// ```
abstract final class FloadAttribution {
  /// This plugin's version.
  static const String version = '1.0.0';

  /// The channel to the native halves. Visible for tests only.
  @visibleForTesting
  static const MethodChannel channel = MethodChannel('com.fload.attribution');

  static bool _warnedMissing = false;

  /// Starts the SDK. Call it once, early in `main()` after
  /// `WidgetsFlutterBinding.ensureInitialized()`. It returns as soon as the
  /// native SDK has the call; the network work runs in the background and
  /// waits on disk until Fload has it.
  ///
  /// [key] is the app's public write key (`fload_pk_…`) from Fload. Change
  /// [endpoint] only to test against a local or staging API.
  static Future<void> configure(
    String key, {
    Uri? endpoint,
    FloadLogLevel logLevel = FloadLogLevel.warning,
  }) {
    return _invoke<void>('configure', <String, Object?>{
      'key': key,
      'endpoint': endpoint?.toString(),
      'logLevel': logLevel.name,
    });
  }

  /// Links your app's user id (for example RevenueCat's app user id) to this
  /// install. Safe before [configure] and on every launch: the same id is
  /// sent once.
  static Future<void> setUserId(String userId) {
    return _invoke<void>('setUserId', <String, Object?>{'userId': userId});
  }

  /// This install's random reference, for Fload support. Null until
  /// [configure] has loaded the SDK's state, and on platforms without the
  /// native SDK.
  static Future<String?> get installReference {
    return _invoke<String>('getInstallReference');
  }

  static Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      if (!_warnedMissing) {
        _warnedMissing = true;
        debugPrint(
          'fload_attribution: no native SDK on this platform, so Fload attribution is off. '
          'It runs on iOS and Android; after adding the plugin, rebuild the app (not a hot restart).',
        );
      }
      return null;
    }
  }
}
