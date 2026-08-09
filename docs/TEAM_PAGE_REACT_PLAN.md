# Manager Team Page → React (API-first) Plan

Rewrite the manager's team page (`app/views/teams/show.html.haml` + `_mantra_team`, `_fanta_team`,
`_team_data_section`, `_team_match_item`) as a React feature.

**Sequence: step 3 of the core-loop React migration** (after lineup + match). This is the manager's
hub — frequently visited, tabbed (matches / transfers / squad), read-mostly.

## Why this page

Central hub a manager returns to constantly. Moderate interactivity (tabs, transfer list, squad),
mostly read. Good value/effort and a natural place to add drag-and-drop once the SPA is in place.

## Current behaviour to preserve (parity checklist)

`teams_controller#show` (`preload_team_show_associations`; already returns a partial `format.json`):

- **Team header** (`_team_data_section`): team name, league/tournament, standing/position, budget,
  logo.
- **Mantra vs fanta** variants (`_mantra_team` / `_fanta_team`) — different layouts.
- **Matches tab** (`_team_match_item`): the team's league matches with results/links.
- **Transfers tab**: incoming/left/outgoing rows with player, positions (flat `.player-position`),
  price, club — status labels (the "Куплено/Покинув/Продано" column with the ellipsis truncation).
- **Squad tab**: the team's players with positions, prices.
- Auth: owner-only actions vs public viewing.

## API design (Phase 1)

- `GET /api/teams/:id` → JSON: header (name, league, tournament, standing, budget, logo), variant
  (mantra/fanta), and the three tab datasets (matches, transfers, squad) — or split into
  `GET /api/teams/:id/matches|transfers|squad` if payloads are large.
- Reuse existing serializers/queries; keep it N+1-safe (transfers → clubs/positions, matches →
  host/guest clubs like the recent `ordered_tournament_matches` fix).

## Frontend architecture (Phase 2)

- Route in `App.tsx`: `/teams/:teamId` (and a redirect/entry from left-nav).
- `app/client/pages/Team/` with: `TeamHeader`, `Tabs`, `MatchesTab`, `TransfersTab` (reuse
  `PositionChips`), `SquadTab`. Reuse existing `ui/` (Table, Tabs).

## Rollout (Phase 3)

- Ship `/teams/:id` behind the SPA route; keep HAML fallback. Parity across mantra/fanta and
  owner/public.
- Component tests + API request specs; retire HAML; drop from Viewport Migration.

## Effort & risks

- ~1 week. Low regression risk (read-mostly). Watch the mantra/fanta variant split.
