#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "🔨 Building Safebite for iOS Simulator..."
BOOTED_SIM=$(xcrun simctl list devices | grep -m1 'Booted' | grep -E -o '[0-9A-F-]{36}' || echo "4C29BC75-A0C1-476F-B99C-1564FF17810C")
echo "📱 Target Simulator: $BOOTED_SIM"

xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$BOOTED_SIM" \
  build

APP_PATH=$(ls -td ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphonesimulator/Runner.app 2>/dev/null | head -n 1)

echo "📱 Terminating previous instance (if running)..."
xcrun simctl terminate booted com.example.safebiteApp 2>/dev/null || true

echo "📱 Installing onto booted simulator..."
xcrun simctl install booted "$APP_PATH"

echo "🚀 Launching Safebite..."
xcrun simctl launch booted com.example.safebiteApp

echo "✅ Safebite is now running in your iOS Simulator!"
