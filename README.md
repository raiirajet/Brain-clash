# Brain Clash – Play. Think. Win.

Flutter + Flame offline learning game. Version 0.1.0 is a development candidate, not a verified release.

SDK baseline: Flutter 3.29.3 / Dart 3.7.x, Flame 1.25.0, shared_preferences 2.5.3. Compatibility must be confirmed by CI.

Run scripts/bootstrap_android.sh with Flutter installed to generate the standard Android scaffold, then flutter pub get, flutter analyze, flutter test and flutter build apk --debug. Debug APK is for testing only. No signing key in source. Android scaffolding and lockfile need to be checked in after successful generation.

Architecture: question_generators (questions), game_engine (state and Flame arena), learning (local persistence), screens/widgets (UI). No backend.
