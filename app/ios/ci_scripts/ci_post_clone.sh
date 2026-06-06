#!/bin/sh
set -e

# ----------------------------------------------------------
# Xcode Cloud post-clone script for Flutter iOS builds
# This runs automatically after Xcode Cloud clones the repo
# ----------------------------------------------------------

echo "==> Installing Flutter SDK..."

# Pin the Flutter version so a floating "stable" can't silently change the
# toolchain (and break the build) between CI runs. Bump this deliberately.
FLUTTER_VERSION="3.41.6"

# Clone the pinned Flutter version
git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

echo "==> Flutter version:"
flutter --version

# This project integrates iOS plugins via CocoaPods (Runner.xcworkspace +
# Pods.xcodeproj), not Swift Package Manager. Newer Flutter releases enable
# SPM by default, which routes plugins through SPM and makes the CocoaPods
# @import (e.g. `@import connectivity_plus;` in GeneratedPluginRegistrant.m)
# fail with "Module not found" during `xcodebuild archive`. Force CocoaPods.
echo "==> Disabling Swift Package Manager (project is CocoaPods-based)..."
flutter config --no-enable-swift-package-manager

# Navigate to the Flutter project root (one level up from ios/)
cd "$CI_PRIMARY_REPOSITORY_PATH/app"

echo "==> Running flutter pub get..."
flutter pub get

echo "==> Running flutter precache for iOS..."
flutter precache --ios

echo "==> Installing CocoaPods dependencies..."
cd ios
pod install --repo-update

echo "==> Build preparation complete!"
