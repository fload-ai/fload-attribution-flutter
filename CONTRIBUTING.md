# Contributing

Written from Apple's and Google's public documentation. Do not paste code from
other attribution SDKs.

This package is a thin layer over Fload's native SDKs. Behaviour (what is sent,
when, retries, storage) belongs in those repos, not here:

- iOS: https://github.com/fload-ai/fload-attribution-ios
- Android: https://github.com/fload-ai/fload-attribution-android

The iOS SDK's sources are vendored byte for byte from a tag of the iOS repo.
Never edit them here: change the iOS SDK, tag it, bump `IOS_SDK_TAG` in
`scripts/vendor-ios-sdk.sh` and run the script. CI fails when the vendored
files differ from the tag.

The example apps send only to the local ingest stub in `tool/`, never to
Fload's production ingest.

## Releasing

Bump `version` in `pubspec.yaml` (and the podspec), add a `CHANGELOG.md`
entry, merge, then push a tag `v<version>` (for example `v1.0.1`). The
`Publish to pub.dev` workflow publishes it with GitHub's OIDC token; pub.dev
accepts it only from this repository and the `v{{version}}` tag pattern.
