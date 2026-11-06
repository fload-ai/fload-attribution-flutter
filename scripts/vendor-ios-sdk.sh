#!/usr/bin/env bash
# Copies the Fload iOS SDK's Swift sources (and its privacy manifest) from a
# tag of github.com/fload-ai/fload-attribution-ios into this package, so the
# Swift Package Manager and CocoaPods builds compile exactly that code.
#
#   scripts/vendor-ios-sdk.sh            # vendor the pinned tag (IOS_SDK_TAG below)
#   scripts/vendor-ios-sdk.sh --check    # fail unless the vendored files are byte-equal to the tag
#
# Never edit the vendored files by hand: change the iOS SDK, tag it, bump the
# pin and run this script.
set -euo pipefail

IOS_SDK_REPO="https://github.com/fload-ai/fload-attribution-ios.git"
IOS_SDK_TAG="1.0.2"

root="$(cd "$(dirname "$0")/.." && pwd)"
dest="$root/ios/fload_attribution/Sources/fload_attribution/Vendor/FloadAttribution"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$IOS_SDK_TAG" "$IOS_SDK_REPO" "$work/sdk"
commit="$(git -C "$work/sdk" rev-parse HEAD)"
source_dir="$work/sdk/Sources/FloadAttribution"
stamp="Vendored from $IOS_SDK_REPO at tag $IOS_SDK_TAG (commit $commit) by scripts/vendor-ios-sdk.sh. Do not edit."

if [[ "${1:-}" == "--check" ]]; then
  if ! diff -r "$source_dir" "$dest" --exclude VENDORED.txt >"$work/diff.txt"; then
    cat "$work/diff.txt"
    echo "The vendored iOS SDK differs from $IOS_SDK_TAG. Run scripts/vendor-ios-sdk.sh." >&2
    exit 1
  fi
  if [[ "$(cat "$dest/VENDORED.txt")" != "$stamp" ]]; then
    echo "VENDORED.txt does not name $IOS_SDK_TAG at $commit. Run scripts/vendor-ios-sdk.sh." >&2
    exit 1
  fi
  echo "Vendored iOS SDK matches $IOS_SDK_TAG ($commit)."
  exit 0
fi

rm -rf "$dest"
mkdir -p "$dest"
cp -R "$source_dir/." "$dest/"
echo "$stamp" >"$dest/VENDORED.txt"
echo "Vendored $IOS_SDK_TAG ($commit) into ${dest#"$root"/}."
