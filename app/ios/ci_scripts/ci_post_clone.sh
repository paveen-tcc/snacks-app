#!/bin/sh
set -e

# ----------------------------------------------------------
# Xcode Cloud post-clone script for Flutter iOS builds
# This runs automatically after Xcode Cloud clones the repo
# ----------------------------------------------------------

echo "==> Installing Flutter SDK..."

# Clone Flutter stable channel
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

echo "==> Flutter version:"
flutter --version

# Navigate to the Flutter project root (one level up from ios/)
cd "$CI_PRIMARY_REPOSITORY_PATH/app"

echo "==> Running flutter pub get..."
flutter pub get

echo "==> Running flutter precache for iOS..."
flutter precache --ios

echo "==> Installing CocoaPods dependencies..."
cd ios
pod install

echo "==> Build preparation complete!"
