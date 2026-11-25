# Brain Clash – Play. Think. Win.

Flutter + Flame offline learning game. Version 0.1.0 is a development candidate, not a verified release.

SDK baseline: Flutter 3.29.3 / Dart 3.7.x, Flame 1.25.0, shared_preferences 2.5.3. Compatibility must be confirmed by CI.

Run scripts/bootstrap_android.sh with Flutter installed to generate the standard Android scaffold, then flutter pub get, flutter analyze, flutter test and flutter build apk --debug. Debug APK is for testing only. No signing key in source. Android scaffolding and lockfile need to be checked in after successful generation.

Architecture: question_generators (questions), game_engine (state and Flame arena), learning (local persistence), screens/widgets (UI). No backend.

Review queue: failed questions become due next training round, then correctly recalled questions recur after 1, 3 and 7 days. Original procedural character artwork and Android vector launcher assets are generated from source.

## Audio
Original sound effects and an optional background loop are synthesized by scripts/synth_audio.py. Android uses SoundPool and MediaPlayer; independent effects, music, haptics and volume settings. Native playback adapter for iOS/Web remains to be implemented.

## Release signing
A tag is eligible for a signed release only after testing and review. Configure GitHub Actions secrets BRAINCLASH_KEYSTORE_B64, BRAINCLASH_STORE_PASSWORD, BRAINCLASH_KEY_ALIAS and BRAINCLASH_KEY_PASSWORD. Preserve the same keystore securely outside GitHub source. Never distribute the debug APK as production; debug keys may differ between CI runners.

Training supports typed numeric answers, voluntary age-based starting levels, automatic adjustment, and number/symbol/colour recognition sequences.

## 0.2.0 candidate
Interactive sequence and pair boards, focus signals, unlockable cosmetics and approved launcher branding. CI builds a universal optimized TEST APK with a non-production key and publishes a marked prerelease. A production signing key is still required.

German/English UI language selection; German spelling and vocabulary content remains available in both UI languages. Device CI includes an emulator offline-start smoke test. Physical multi-touch, performance and update testing remain required before a production release.

## 0.9.5 release candidate
Run `bash scripts/bootstrap_android.sh` before analysis/build (generates audio and fetches immutable verified OFL fonts). All runtime gameplay remains offline. See docs/masterplan-status.md for release gates. Candidate builds must not be represented as production signed.
