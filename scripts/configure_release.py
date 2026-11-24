from pathlib import Path
import os
required=['BRAINCLASH_KEYSTORE','BRAINCLASH_STORE_PASSWORD','BRAINCLASH_KEY_ALIAS','BRAINCLASH_KEY_PASSWORD']
if not all(os.environ.get(k) for k in required):
    raise SystemExit('Missing signing configuration')
p=Path('android/app/build.gradle.kts')
s=p.read_text()
needle='android {'
debug='signingConfig = signingConfigs.getByName("debug")'
if needle not in s or debug not in s:
    raise SystemExit('Unexpected Android Gradle template; refusing fallback signing')
s=s.replace(needle,'''android {
    signingConfigs {
        create("brainClashRelease") {
            storeFile = file(System.getenv("BRAINCLASH_KEYSTORE"))
            storePassword = System.getenv("BRAINCLASH_STORE_PASSWORD")
            keyAlias = System.getenv("BRAINCLASH_KEY_ALIAS")
            keyPassword = System.getenv("BRAINCLASH_KEY_PASSWORD")
        }
    }
''',1).replace(debug,'signingConfig = signingConfigs.getByName("brainClashRelease")')
p.write_text(s)
