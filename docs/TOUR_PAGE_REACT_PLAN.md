# Tour (Round) Page → React (API-first) Plan

Rewrite the tour/round hub (`app/views/tours/show.html.haml` + `_round_matches`, `_stats_section`,
`_tournament_players`, `_league_players`, `_fanta_round`, `_mob_show`, `_mob_mantra_matches`) as a
React feature.

**Sequence: step 4 of the core-loop React migration** (after lineup + match + team). The main win
here is **SPA cohesion**: the tour page is the navigation hub that links to setting a lineup, opening
matches, and viewing stats — once those are React, making the tour page React removes the last
full-page reloads in the core loop.

## Why this page

Central per-round hub. Medium interactivity (tabs: matches / results / tournament-players /
league-players). Its value is less about local statefulness and more about stitching the core loop
into seamless client-side navigation (no reloads between tour → match → lineup).

## Current behaviour to preserve (parity checklist)

`tours_controller#show` + the tab endpoints already return HTML partials:

- **Round matches** (`_round_matches`, `ordered_tournament_matches`) with links into match pages and
  the "set/edit lineup" entry points.
- **Results** (`@results_ordered`, `@results_by_score`) — league standings + top-5 by score.
- **Tournament players** tab — `GET /tours/:id/tournament_players` (`round_players.with_score`,
  `@teams_by_player`), currently rendered as an HTML partial.
- **League players** tab — `GET /tours/:id/league_players` (`MatchPlayer.by_tour.main_with_score`).
- **Fanta vs mantra** variants (`_fanta_round` / mantra) and a **mobile** layout (`_mob_show`).
- Actions: `update` (tour state), `inject_scores` (admin) — keep server-side; the page just links.

## API design (Phase 1)

- `GET /api/tours/:id` → JSON: round meta, matches (host/guest clubs, scores, lineup-entry links),
  results (ordered + top-5), variant (fanta/mantra), and the user's teams/lineup status for the
  round (to drive the "set lineup" CTAs).
- `GET /api/tours/:id/tournament_players` and `.../league_players` → JSON (the two stat tabs are
  already partial-rendered; convert the payloads to JSON). Keep N+1-safe.

## Frontend architecture (Phase 2)

- Route in `App.tsx`: `/tours/:tourId`.
- `app/client/pages/Tour/` with: `RoundMatches` (links to `/matches/:id`), `Standings`,
  `TournamentPlayersTab`, `LeaguePlayersTab`, `TourTabs`, and CTA blocks routing to the React lineup
  builder. Reuse `ui/` (Table, Tabs) and the players components from the existing Players/RoundPlayers
  React pages (much of the stat-tab UI already exists there).

## Rollout (Phase 3)

- Ship `/tours/:id` behind the SPA route; keep HAML fallback. Verify the fanta/mantra + mobile
  variants and that every navigation target (match, lineup) is a client-side route by this point.
- Component tests + API specs; retire HAML; drop from Viewport Migration.

## Effort & risks

- ~1 week; lower if the RoundPlayers/Players React components are reused for the stat tabs.
- Low regression risk. Dependency: most value only materializes once match + lineup are already
  React (otherwise the tour page still reloads into HAML pages), so keep it at step 4.
