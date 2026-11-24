# Brain Clash 0.9.5 – release candidate
## Implemented
- Dedicated deterministic arcade rules: tower blocks and errors; race distance; rocket fuel, velocity and time integration; maze navigation with generated connected layouts; treasure keys and individually opened chests; escape locks; boss phases and team health.
- Word Sprint, Logic Escape and Boss Battle (team or training). Number Bomb keeps an individual eight-second fuse.
- Twelve vector fighters with five cosmetic palettes, twelve attack effects, six procedural arenas, victory particles and six original arena tracks.
- Outfit/Inter fetched at build time from an immutable Google Fonts revision and verified using Git blob hashes. OFL license text bundled; no runtime download.
- Responsive portrait/landscape/tablet battle layouts. Added multi-pointer widget tests and Android SQLite migration coverage. English translations expanded, German word-learning content intentionally remains German.
- GitHub CI derives the APK name from pubspec; emulator workflow is a release dependency. Existing profiles, signing configuration and app ID preserved.
## Release gates (must be evidenced, not assumed)
- Successful Flutter analyzer, unit/widget tests and Android build; offline emulator integration test.
- Physical Android phone/tablet tests: real capacitive multitouch, 60 FPS/thermal and cold start; rotation, interruption, accessibility and migration from an installed prior signed APK.
- Owner-managed permanent production keystore, configured repository secrets and explicit production tag. Test APKs are NOT production-signed. Never uninstall an older installation without safeguarding its data.
- Review all English strings and actual store screenshots. No store upload or 1.0 tag until gates pass.
