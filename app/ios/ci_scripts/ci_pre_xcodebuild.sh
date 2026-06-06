#!/bin/sh
set -e

# ----------------------------------------------------------
# Xcode Cloud pre-xcodebuild script
# Runs after dependencies are resolved, just before `xcodebuild`.
#
# Aligns the iOS build number (CFBundleVersion) with the Xcode Cloud
# build number so TestFlight / App Store Connect and Xcode Cloud always
# show the SAME number. This removes the need to hand-bump the `+N` build
# number in pubspec.yaml and avoids duplicate-build-number upload rejects.
#
# The marketing version (FLUTTER_BUILD_NAME, e.g. 1.5.0) is still owned by
# pubspec.yaml — bump that only when you ship a new version.
# ----------------------------------------------------------

GENERATED_XCCONFIG="$CI_PRIMARY_REPOSITORY_PATH/app/ios/Flutter/Generated.xcconfig"

if [ -z "$CI_BUILD_NUMBER" ]; then
  echo "==> CI_BUILD_NUMBER not set; leaving build number from pubspec.yaml unchanged."
  exit 0
fi

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "==> $GENERATED_XCCONFIG not found (did flutter pub get run in ci_post_clone.sh?)."
  exit 1
fi

echo "==> Setting iOS build number (CFBundleVersion) to Xcode Cloud build number: $CI_BUILD_NUMBER"

if grep -q '^FLUTTER_BUILD_NUMBER=' "$GENERATED_XCCONFIG"; then
  sed -i '' "s/^FLUTTER_BUILD_NUMBER=.*/FLUTTER_BUILD_NUMBER=$CI_BUILD_NUMBER/" "$GENERATED_XCCONFIG"
else
  echo "FLUTTER_BUILD_NUMBER=$CI_BUILD_NUMBER" >> "$GENERATED_XCCONFIG"
fi

echo "==> Resulting version lines:"
grep -E '^FLUTTER_BUILD_(NAME|NUMBER)=' "$GENERATED_XCCONFIG"
