#!/usr/bin/env bash
# One-time setup: generates the android/ios platform folders around the
# UniHive Dart code, installs packages, and builds the icon + splash.
# Run from this folder:  bash setup.sh
set -e

command -v flutter >/dev/null || { echo "Flutter not found. Install it first: https://docs.flutter.dev/get-started/install"; exit 1; }

echo "▶ Generating platform folders (existing lib/ files are kept)…"
flutter create --org shop.unihive --project-name unihive --platforms android,ios .

MANIFEST=android/app/src/main/AndroidManifest.xml

echo "▶ Setting app name to UniHive…"
perl -0pi -e 's/android:label="[^"]*"/android:label="UniHive"/' "$MANIFEST"

if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  echo "▶ Adding INTERNET permission (needed for fonts, images, live data)…"
  perl -0pi -e 's#(<manifest[^>]*>)#$1\n    <uses-permission android:name="android.permission.INTERNET"/>#' "$MANIFEST"
fi

if ! grep -q 'android:scheme="https"' "$MANIFEST"; then
  echo "▶ Allowing the app to open ticket links in the browser…"
  perl -0pi -e 's#<queries>#<queries>\n        <intent>\n            <action android:name="android.intent.action.VIEW" />\n            <data android:scheme="https" />\n        </intent>#' "$MANIFEST"
fi

if [ -f ios/Runner/Info.plist ]; then
  perl -0pi -e 's#(<key>CFBundleDisplayName</key>\s*<string>)[^<]*#${1}UniHive#' ios/Runner/Info.plist
fi

echo "▶ Installing packages…"
flutter pub get

echo "▶ Generating launcher icons and splash screen…"
dart run flutter_launcher_icons
dart run flutter_native_splash:create

echo ""
echo "✅ Done. Plug in an Android phone (USB debugging on) or start an emulator, then run:"
echo "   flutter run"
echo ""
echo "When you're ready for the Play Store, follow README.md → 'Publish to Google Play'."
