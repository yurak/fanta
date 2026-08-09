# Match Page → React (API-first) Plan

Rewrite the match page (`app/views/matches/show.html.haml` + `_main_player`, `_subs_player`,
`_team_squad`, `_real-match`, `_mp_bonuses`) as a React feature.

**Sequence: step 2 of the core-loop React migration** (after the lineup builder). Best value/effort:
high view frequency, **mostly read-only** → low regression risk, and it is the natural home for the
backlog item *"Player form on the match page"* (reuse the form-strip component already built for the
lineup picker modal).

## Why this page

Frequently viewed, data-rich (both squads, real positions, scores, bonuses/maluses, substitutions,
module diagrams). Read-mostly, so it is the safest early win to prove the API-first pattern on a
consumer screen and to make the core loop feel like a cohesive SPA.

## Current behaviour to preserve (parity checklist)

`matches_controller#show` loads (see `#match`, `#preload_lineups`, `#preload_round_matches`):

- **Match header**: host/guest clubs, score, kickoff/status, league/tournament context.
- **Two squads** (`_team_squad`): main players by real position + subs + not-in-squad, each with:
  avatar/kit, name, position chips (flat `.player-position` style), per-player match score and
  **bonuses/maluses breakdown** (`_mp_bonuses`), substitution markers (`subs_string`).
- **Module diagram** (`_real-match`): mini-pitch with each slot's module position
  (`.module-position-block`) and the player who filled it.
- **Round navigation**: prev/next tour match (`@prev_tour_match` / `@next_tour_match`) and the round's
  other matches (`preload_round_matches`).
- **Auth-gated details**: lineups shown only to the team owner or once the tour is `deadlined?`.
- **New**: add the last-N-rounds **form strip** per player (backlog item) using the existing
  `players_last_rounds_form` helper / a shared component.

## API design (Phase 1)

- `GET /api/matches/:id` → JSON: match header, both lineups (main/subs/not-in-squad) with per-player
  `{ name, positions, club, real_position, score, bonuses:[…], maluses:[…], subs:{in,out}, form:[…] }`,
  module diagrams, prev/next match ids + round matches, and an `authorized` flag (owner/deadlined)
  that gates the squad details server-side.
- Serialize what `_team_squad` / `_mp_bonuses` render today; keep the bonus/malus math on the server
  (`RoundPlayer#result_score`, `bonuses`, `maluses`) — **do not** recompute in JS.
- Keep it **N+1-safe**: mirror the existing `preload_lineups` includes and the `/slots` /
  `ordered_tournament_matches` eager-loading fixes.

## Frontend architecture (Phase 2)

- Route in `App.tsx`: `/matches/:matchId`.
- `app/client/pages/Match/` with: `MatchHeader`, `TeamSquad` (main/subs/not-in-squad columns),
  `PlayerRow` (avatar, `PositionChips`, `FormStrip`, score + `BonusBreakdown`, sub markers),
  `ModuleDiagram`, `RoundNav`.
- Reuse existing `ui/` and the `PositionChips` / `FormStrip` components (extract `FormStrip` from the
  lineup picker so both share it).
- Read-only: no local mutation beyond expand/collapse of bonus breakdowns and nav.

## Rollout (Phase 3)

- Ship behind the `/matches/:id` SPA route; keep HAML as fallback.
- Parity check: same players, scores, bonus/malus totals, subs, and diagram vs the HAML page across
  mantra / eurocup / national matches and pre/post-deadline auth states.
- Component tests + an API request spec; then retire the HAML views and drop from Viewport Migration.

## Effort & risks

- ~1 week (read-only, but two squads × many player states + bonus breakdown + diagram).
- Low regression risk (no writes). Main risks: bonus/malus serialization parity and the auth gating
  of squad visibility — replicate both exactly.
