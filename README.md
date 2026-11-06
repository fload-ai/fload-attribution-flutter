# Fload Attribution for Flutter

Counts your app's installs in Fload and attributes them: to Apple Ads through
Apple's AdServices API on iOS, and with Google Play's Install Referrer on
Android. No IDFA, no advertising ID, no App Tracking Transparency prompt.

The plugin is a thin layer over Fload's native SDKs,
[iOS](https://github.com/fload-ai/fload-attribution-ios) and
[Android](https://github.com/fload-ai/fload-attribution-android), which do
all the work. iOS builds with Swift Package Manager or CocoaPods.

Needs iOS 15+ and Android API 24+ (`minSdk = 24`), and Flutter 3.22 or later.

## Install

```sh
flutter pub add fload_attribution
```

**iOS:** set the deployment target to 15.0 or later. With CocoaPods, that is
`platform :ios, '15.0'` in `ios/Podfile`.

**Android:** set `minSdk = 24` or higher in `android/app/build.gradle.kts`.
The Fload Android SDK comes from [JitPack](https://jitpack.io), and the plugin
adds JitPack to your projects for that one group. If your
`settings.gradle(.kts)` uses `RepositoriesMode.FAIL_ON_PROJECT_REPOS`, add it
there yourself:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io") { content { includeGroup("com.github.fload-ai") } }
    }
}
```

## Use

```dart
import 'package:fload_attribution/fload_attribution.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FloadAttribution.configure('fload_pk_…');
  runApp(const MyApp());
}

// Optional: link your user id (e.g. RevenueCat's app user id) to the install.
FloadAttribution.setUserId(await Purchases.appUserID);
```

The key is your app's public write key from Fload. It can only report
installs for that one app, so it is safe to ship in the binary.

| Call | What it does |
| --- | --- |
| `FloadAttribution.configure(key, {endpoint, logLevel})` | Starts the native SDK. Call it once a launch. Returns at once. |
| `FloadAttribution.setUserId(userId)` | Links a user id to this install. Safe before `configure` and on every launch: the same id is sent once. |
| `FloadAttribution.installReference` | This install's random reference, for Fload support. `null` until the SDK has loaded its state. |

`endpoint` is only for testing against your own API. `logLevel` is a
`FloadLogLevel`: `none`, `error`, `warning` (the default), `info` or `debug`.

## What it does

- On the first launch with the SDK it makes a random install reference and
  reports the install once: app id, version and build, OS version, device
  model, locale and first-launch time. On iOS it adds Apple's AdServices
  attribution token, which Fload swaps with Apple server side. On Android it
  adds what Play's Install Referrer API returns.
- `setUserId` sends your user id with the install, or afterwards in a
  separate request. Each id is sent once.
- Everything waits in a small file queue (excluded from backups) until Fload
  accepts it, across relaunches and network loss, with exponential backoff.
  A retry repeats the same ids, so Fload counts the install once.
- It sends when configured, when the app comes to the foreground and when the
  network comes back. All work runs off the UI thread.

Details, and what happens on a refused or revoked key, are in the native
READMEs. It never logs the key, the token, the referrer or the user id. On
platforms other than iOS and Android, the calls do nothing.

## Notes

- **Existing users:** the first launch of an app version with the SDK counts
  as an install, for existing users too.
- **Reinstalls** and devices restored from a backup are new installs.
- The **iOS Simulator** has no AdServices token; its installs arrive without
  one. An **Android emulator** with the Play Store reports Play's organic
  referrer (`utm_source=google-play&utm_medium=organic`).

## Privacy

The iOS privacy manifest (`PrivacyInfo.xcprivacy`) ships with the plugin: no
tracking, no tracking domains, no required-reason APIs. Collected, linked to
the user, not used for tracking, for analytics: a device ID (the random
install reference), advertising data (the AdServices token) and a user ID
(only when you call `setUserId`). Declare the same in your App Store privacy
answers. For Google Play's Data safety form, see the
[Android README](https://github.com/fload-ai/fload-attribution-android#google-play-data-safety).

## Testing against your own API

```dart
FloadAttribution.configure(key, endpoint: Uri.parse('http://localhost:3001'), logLevel: FloadLogLevel.debug);
```

On the Android emulator the host is `http://10.0.2.2:<port>`, and a plain
`http` endpoint needs cleartext allowed for that host.

`tool/ingest-stub.mjs` is a local stand-in for Fload's ingest. It checks each
request against the wire contract and answers `202`. The example app sends
only to it:

```sh
node tool/ingest-stub.mjs        # the stub, on port 3999
cd example && flutter run         # an iOS simulator or Android emulator
curl localhost:3999/__requests
```

Tests: `flutter test` (the Dart API, with the channel mocked);
`cd example/android && ./gradlew :fload_attribution:testDebugUnitTest`
(the Kotlin half); the Swift half's tests run in `example/ios`'s
`RunnerTests`; `cd example && flutter test integration_test` runs on a
simulator or emulator against the stub.

## How it is built

- `lib/fload_attribution.dart` calls the native halves over one method
  channel, `com.fload.attribution`. Nothing is duplicated in Dart.
- iOS: `ios/fload_attribution/Package.swift` (Swift Package Manager) and
  `ios/fload_attribution.podspec` (CocoaPods) build the same files: the
  plugin class and the Fload iOS SDK. The SDK's sources are vendored byte for
  byte under `ios/fload_attribution/Sources/fload_attribution/Vendor` from a
  tag of the iOS repo. `scripts/vendor-ios-sdk.sh` refreshes them and
  `scripts/vendor-ios-sdk.sh --check` verifies them.
- Android: the plugin depends on the Fload Android SDK
  (`com.github.fload-ai:fload-attribution-android:1.0.2`, from JitPack).

## License

License: MIT. See [LICENSE](LICENSE).
