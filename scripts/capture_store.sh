#!/usr/bin/env bash
set -euo pipefail
# Local adb/VM service transport only; release manifest stays offline.
python3 - <<'PY'
from pathlib import Path
p=Path('android/app/src/debug/AndroidManifest.xml')
s=p.read_text().replace('</manifest>','<uses-permission android:name="android.permission.INTERNET"/>\n</manifest>')
p.write_text(s)
PY
flutter drive --driver=test_driver/store_driver.dart --target=integration_test/store_capture_test.dart -d emulator-5554
