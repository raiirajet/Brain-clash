#!/usr/bin/env bash
set -euo pipefail
adb shell svc wifi disable
adb shell svc data disable
# Integration test requires local host transport through ADB, not internet.
flutter test integration_test/app_test.dart -d emulator-5554
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am force-stop ch.brainclash.brain_clash
adb shell am start -W -n ch.brainclash.brain_clash/.MainActivity
adb shell pidof ch.brainclash.brain_clash
adb logcat -d -s AndroidRuntime:E > /tmp/brainclash-runtime.txt
cat /tmp/brainclash-runtime.txt
