#!/usr/bin/env bash
set -euo pipefail
adb shell svc wifi disable
adb shell svc data disable
# Integration test requires local host transport through ADB, not internet.
python3 - <<'PY'
from pathlib import Path
p=Path('android/app/src/debug/AndroidManifest.xml')
s=p.read_text().replace('</manifest>','<uses-permission android:name="android.permission.INTERNET"/>\n</manifest>')
p.write_text(s)
PY
flutter test integration_test/app_test.dart -d emulator-5554
bash scripts/bootstrap_android.sh
bash scripts/retry_dependency_build.sh flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am force-stop ch.brainclash.brain_clash
adb shell am start -W -n ch.brainclash.brain_clash/.MainActivity
adb shell pidof ch.brainclash.brain_clash
mkdir -p output/device
adb shell am start -W -n ch.brainclash.brain_clash/.MainActivity > output/device/cold-start.txt
adb shell dumpsys gfxinfo ch.brainclash.brain_clash > output/device/gfxinfo.txt
adb exec-out screencap -p > output/device/home.png
adb logcat -d -s AndroidRuntime:E > /tmp/brainclash-runtime.txt
cat /tmp/brainclash-runtime.txt
