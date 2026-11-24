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
