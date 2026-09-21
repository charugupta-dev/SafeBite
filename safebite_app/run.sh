#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "🔨 Building Safebite for iOS Simulator..."
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build -quiet

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphonesimulator -name "Runner.app" -maxdepth 1 | head -n 1)

echo "📱 Installing onto booted simulator..."
xcrun simctl install booted "$APP_PATH"

echo "🚀 Launching Safebite..."
xcrun simctl launch booted com.example.safebiteApp

echo "✅ Safebite is now running in your iOS Simulator!"
