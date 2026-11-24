#!/usr/bin/env bash
set -euo pipefail
if [ ! -d android ]; then
  tmp="$(mktemp -d)"
  flutter create --no-pub --platforms=android --org ch.brainclash --project-name brain_clash "$tmp/brain_clash"
  cp -R "$tmp/brain_clash/android" .
  rm -rf "$tmp"
fi
python3 - <<'PY'
from pathlib import Path
p=Path('android/app/src/main/AndroidManifest.xml')
s=p.read_text().replace('android:label="brain_clash"','android:label="Brain Clash"')
if 'android:allowBackup=' not in s:
 s=s.replace('<application','<application android:allowBackup="false" android:fullBackupContent="false"')
p.write_text(s)
PY
