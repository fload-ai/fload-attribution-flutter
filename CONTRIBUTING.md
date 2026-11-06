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
