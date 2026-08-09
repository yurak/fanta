# Lineup Builder → React (API-first) Plan

Plan for rewriting the lineup **create/edit** page (`app/views/lineups/_lineup_form.html.haml`
+ `new.html.haml` / `edit.html.haml`) as a React feature.

## Why this page

It is the most stateful, interactive screen in the app and currently the least maintainable code:
a ~350-line inline `:javascript` block inside a HAML partial, with Ruby interpolated into JS
(`"#{tour.national?}"`, `"#{t('...')}"`), hand-rolled DOM mutation, and validation via `alert()`.
React replaces all of that with managed state and testable components. It also aligns with two
backlog items: **Viewport Migration** (this page leaves the legacy-HAML scope) and **Token auth +
Flutter app** (the JSON endpoints below are shared with the mobile app).

## Current behaviour to preserve (parity checklist)

- **Modes / variants**: `new` (empty squad) and `edit` (existing lineup); tournament kinds
  **mantra**, **eurocup**, **national** — each with different candidate sources and limits.
- **Squad shape**: 11 main slots (by `TeamModule`) + reserves; GK slot special-cased; slot position
  and location per index.
- **Player selection**: per-slot modal listing candidates grouped by malus tier `0` / `1.5` / `3.0`
  (`available_by_slot`), reserves via `available_for_select`; search/filter; lazy loading of
  candidates via `GET /slots` (currently returns **HTML** `team_players_html`).
- **Module switching**: choosing another `TeamModule` reloads the slot layout.
- **Field diagram**: `_team_field` mini-pitch mirrors chosen players (`.match-module-item-player`).
- **Live rules feedback**: duplicate detection (`markDuplicates`), country/club count badges for
  national/eurocup (`#national-players-*` / `#club-players-*`), malus/⚠️ markers, position chips,
  the last-5-rounds **form strip** (`players_last_rounds_form`).
- **Clear squad**: client-only reset (no DB write) — already added.
- **Submit validation** (currently `alert()`): total players count, per-country / per-club
  min/max limits, national teams count, no duplicates.
- **Save**: `POST /teams/:team_id/lineups` (create) / `PATCH` (update) with nested
  `match_players_attributes` (`round_player_id` per index); server maps `player_id → RoundPlayer`
  via `recount_round_players_params` (find_or_create RoundPlayer for the round).

## API design (Phase 1 — do first)

Expose JSON so the React app never scrapes HTML. Reuse existing services.

- `GET /api/lineups/new?team_id&tour_id&team_module_id` → bootstrap: tour meta (kind, limits,
  `national_teams_count`), modules list, slots (index, position, location), current selections
  (for edit), field layout, i18n-ready labels.
- `GET /api/slots?...` (JSON): candidates for a slot grouped by malus tier + reserves, each candidate
  with `{ id, name, first_name, positions, club{code,color,logo}, opponent, in_squad, form: [cells] }`
  — i.e. serialize what `_lineup_player_item` renders today. (Keep the current HTML endpoint until the
  React version ships.)
- `POST /api/lineups` / `PATCH /api/lineups/:id` (JSON): `{ team_module_id, tour_id, slots: [{index,
  player_id}] }`. Server maps `player_id → round_player_id` (reuse `recount_round_players_params`),
  runs the same validations server-side (authoritative), returns `{ ok, errors: [...] }`.
- **Validation must live server-side too** — the JS checks are a UX convenience, not the source of
  truth. Extract the rule set (count/limits/duplicates) into a `Lineups::Validator` service used by
  both the API and any server path.

Depends on / overlaps with the **Token auth + `/api`** backlog item — coordinate so `/api/lineups*`
lands behind the same auth story.

## Frontend architecture (Phase 2)

- New route in `app/client/App.tsx`: `/teams/:teamId/lineups/new` and `/…/:lineupId/edit`
  (react-router already drives the SPA).
- Feature folder `app/client/pages/LineupBuilder/` with components:
  - `LineupBuilder` (page/state root — holds `slots`, `module`, `dirty`, `errors`).
  - `FieldDiagram`, `SlotRow` (avatar, name, position chips, form strip, opponent),
    `PlayerPickerModal` (search + malus groups + candidate cards), `ModulePicker`,
    `SquadRules` (live counters + validation summary), `PositionChips`, `FormStrip`.
  - Reuse existing `ui/` (Drawer, Switcher, Input, Search, Table) and CSS modules.
- **State**: a single reducer for the squad (`{ [index]: player }`) + derived selectors for
  duplicates/counters; no DOM mutation. Data fetching via the existing client data layer.
- **Validation UX**: replace `alert()` with **inline feedback** — highlight offending slots/badges,
  show "selected X/11", disable submit while invalid; use a toast/modal only for the final
  server-rejected case. (This is the real UX win, not merely alert→modal.)

## Rollout (Phase 3)

- Ship behind a route/flag; keep the HAML page as fallback.
- **Parity gate**: verify create/edit save produces identical `match_players` / `round_player_id`
  rows as the HAML flow (this feeds scoring — highest-risk area). Diff a set of real lineups.
- Cover mantra / eurocup / national + new/edit in request specs (API) and component tests.
- Once verified, remove the HAML form, its inline JS, and now-dead helpers; drop the page from the
  Viewport Migration scope.

## Effort & sequencing

- Phase 1 (JSON API + `Lineups::Validator`): ~2–4 days.
- Phase 2 (React builder, all variants): the bulk, ~1–2 weeks.
- Phase 3 (parity, tests, cutover): ~2–4 days.
- Total: a multi-week epic. Do **not** also do the interim "extract inline JS to Stimulus" step —
  it would be thrown away once React lands.

## Risks

- Feature parity across mantra/eurocup/national and new/edit is the main risk; enumerate every
  branch of the current inline JS before starting.
- Save path affects scoring — guard with parity diffing and specs.
- Serializing candidates must stay N+1-safe (see the recent `/slots` eager-loading fixes and the
  `players_last_rounds_form` single-query pattern).
