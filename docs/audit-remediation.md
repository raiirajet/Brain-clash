# 0.9.8+10 stabilization candidate — verification pending

Changes made in response to the independent 0.9.7 audit:
- CI root cause: both failures in audit_regression_test.dart were runtime type errors in Progress.record caused by inferred Map<String,int> values receiving String/List values. Use dynamic-valued maps; retain the regression tests.
- Nonzero rest division, richer percent/decimal/fraction/order-of-operations generators, larger sort/target boards and 24 German spelling words.
- Per-player arcade lane difficulty (tower, maze, treasure, escape) and Number Bomb fuse; boss is cooperative with a common arena difficulty. Math Race and Rocket Race retain a fixed finish line; difficulty applies to questions. Boss strikes use exact scheduled timestamps.
- First correct attempt: 10 XP; corrected task: 5 XP once; daily/weekly goals count first-attempt successes. Existing XP is retained. Historical combined ratings are archived on migration; human and bot ratings each start at 1000. At most one adaptive level/digit change per training session.
- Delete profile-specific quick start and references to the deleted opponent; invalidate associated series checkpoints. New race labels distinguish target from timed rounds.
- New arithmetic properties (40,960 generated cases in the main loops plus narrow-range checks), boss partition, fuse handicap, speed boundaries, profile recreation and XP/rating regression tests.
- Node 24-compatible checkout/setup-java, Gradle caching, dependency-only backoff and debug dependency prewarm. The prior emulator failure was Maven HTTP 429; external availability cannot be guaranteed.

Release evidence: the 0.9.7 run 45462271961 had 146 passes and two failures, with no APK. Run 45462272287 failed resolving Kotlin dependencies from Maven (HTTP 429). These are historical runs, not proof of the new version. A green workflow on the final candidate SHA is mandatory. Do not publish a production release on the basis of source changes alone.

Remaining release gates: real-device multitouch, 48dp targets and large text across supported layouts, full tournament/best-of restart and process-death recovery, complete generator/rule/mode persistence matrix, full DE/EN review, signed upgrade with owner key and data comparison, recorded performance on reference devices, and green CI/APK verification. Automated tests added here do not replace physical-device tests. No claim that all gates have passed.

Previous candidate notes follow for historical context.

# 0.9.7 audit remediation candidate

Implemented:
- normalized per-game arithmetic options; manual digits remain exact except constrained no-carry combinations; age presets and game-specific difficulty behavior expanded.
- Word Sprint clue bank, variable target/tap tasks, larger mazes per tier with regenerated stages, changing treasure allocation, tower/lock goals and boss health scaling, tier-specific fuse timer.
- bounded 30s overtime, equal-setting Speed Battle guard and identical tasks for matching speed settings, objective results, stage feedback, second-player statistics.
- first-attempt mastery in comparable training settings, separated XP and local competitive rating (not Elo), XP breakdown, qualified participation/record bonuses, review routing, save retry.
- per-profile quick-start settings, completed best-of series checkpoints with draw cap, tournament choices and persisted bracket validation, instructions.
- regression tests and supported-mode/rule simulation matrix.

Compatibility: existing XP, profiles, assets, database schema and package ID retained. Old global quick-start configuration is not imported into another profile; users establish a new profile-specific setup on their next round. Active unfinished rounds are intentionally not restored; completed series rounds are retained. Manual digit choices remain user-controlled.

Still open: real-device calibration of learning thresholds and touch accessibility; richer curricula, multiple boss art designs and more sophisticated competitive rating, comprehensive localization and tutorial review; interruption recovery beyond completed series rounds, comprehensive tournament execution/restart tests, remaining lint and formatting work, measured device performance and signed-upgrade tests. New CI must pass before release; production signing needs owner key. No claim of full remediation until evidence.
