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

# Original vector launcher artwork. No borrowed graphics.
python3 - <<'PY'
from pathlib import Path
res=Path('android/app/src/main/res')
drawable=res/'drawable'
drawable.mkdir(exist_ok=True)
icon='''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
<path android:fillColor="#101B38" android:pathData="M0,0 L108,0 L108,108 L0,108 Z"/>
<path android:fillColor="#2468E5" android:pathData="M22,30 Q22,20 34,20 L54,20 L54,88 L34,88 Q22,88 22,76 Z"/>
<path android:fillColor="#F58B46" android:pathData="M54,20 L74,20 Q86,20 86,30 L86,76 Q86,88 74,88 L54,88 Z"/>
<path android:fillColor="#FFFFFF" android:pathData="M60,30 L38,57 L52,57 L48,79 L71,48 L57,48 Z"/>
</vector>'''
(drawable/'brain_clash_icon.xml').write_text(icon)
adaptive=res/'mipmap-anydpi-v26'
adaptive.mkdir(exist_ok=True)
(adaptive/'ic_launcher.xml').write_text('''<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@android:color/black"/><foreground android:drawable="@drawable/brain_clash_icon"/></adaptive-icon>''')
p=Path('android/app/src/main/AndroidManifest.xml')
s=p.read_text().replace('android:icon="@mipmap/ic_launcher"','android:icon="@drawable/brain_clash_icon"')
# Adaptive icon requires Android 26; retain a legacy vector for lower versions.
legacy=res/'mipmap-anydpi'
legacy.mkdir(exist_ok=True)
(legacy/'brain_clash_launcher.xml').write_text(icon)
(adaptive/'brain_clash_launcher.xml').write_text((adaptive/'ic_launcher.xml').read_text())
p.write_text(s.replace('android:icon="@drawable/brain_clash_icon"','android:icon="@mipmap/brain_clash_launcher"'))
PY
