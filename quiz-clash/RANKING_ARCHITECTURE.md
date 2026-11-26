# Ranking – local v1, online preparation
Current mode: local profiles, no external communication. Player id is opaque, stable and separate from nickname. Ranking logic (RankModel) is independent of Android and tested. Local storage is not a trusted server score.
 
## Proposed online contract (not deployed)
- Opt-in guardian-appropriate setup; no real names, school, location, photos, messaging or public contact information. Default private; moderation and nickname filtering, report/hide and deletion controls before public availability.
- Authenticated opaque account identifier; public projection only pseudonym, generated avatar parameters, rank and aggregate score. Do not expose individual answers or school data.
- Versioned built-in question identifiers, server-managed question bank; server-issued quiz session and server-validated answers with idempotency and per-user/per-question uniqueness. Never trust client XP or submitted totals. Rate limits and abuse detection.
- Server computes class and overall ranks from unique accepted question IDs. Scope and participation choices private by default; age-appropriate cohorts, no location or school grouping. Equal scores share competition rank. Database indexes on scope, score and stable id. Paginated read model, own rank, top ten, no fake results.
- Online participation and score transfer require explicit opt-in, data retention and deletion policy. Local achievements must not automatically become verified online points. No credentials or Firebase rules provisioned by this change.
- Future repository/service replaces local rankEntries read path, retaining display model. API authorization, tests, abuse review and privacy review remain required.
