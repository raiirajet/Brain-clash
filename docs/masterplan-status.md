# Brain Clash Masterplan – development candidate 0.5.0

Implemented in this candidate: staged configuration, additional maths generators and options, separate stage art for six maths arcade variants, independent local keypads, first-to-ten/perfect/speed rules, reaction false starts, daily correct-answer goal, XP bonuses, rank and recent local history. Existing profile format retained. Existing Flame arena remains for other modes.

Not release-ready: arcade stage art is not a complete independent game mechanic (bomb/maze/treasure/races still share the maths scoring engine), quick-start saves only core settings, no dedicated target hunt/drag sorting/tournaments/series, no new sprite packs or arena/audio assets, no SQLite migration, not fully localized, no device profiling or production signing verification. CI and physical device tests required before merge/release.
