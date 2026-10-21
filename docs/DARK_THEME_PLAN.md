# Dark Theme Plan

Plan for adding a site dark theme. Decisions locked (2026-08-08):

- **Default**: light; dark is opt-in via a toggle (no auto `prefers-color-scheme`).
- **Persistence**: cookie (`theme`), read server-side so `<html data-theme>` is set before first byte → no FOUC.
- **Scope**: client-facing only — public pages + React SPA. **Out of scope**: `manage`, `rails_admin`, `devise`, mailer/email templates.

## Current state (re-audited 2026-10-09, with counts)

- **Server-side (Rails)**: 34 SCSS files, 18.8k lines, 92 distinct hexes over 1,119 occurrences.
  1,062 of those are client-facing (79 distinct); the 57 left sit in `manage`/`rails_admin`/`devise`
  and are out of scope. Also 58 `rgba()` (15 distinct — shadows and overlays) and 2 named colors.
- **React**: 65 CSS modules, 357 hex occurrences. `var(--…)` is already common
  (`--icon-color`, `--border-color`, `--background-color`, …) but only as per-component parameters.
  One file, `PlayerPage.module.scss`, declares a local palette (`$text $grey $blue $lilac $border
  $row-border $highlight $gold $purple $blank`) — the token vocabulary below grew out of it.
- **The palette is concentrated**: the top 15 colors cover 82% of all occurrences, and 40 colors
  appear exactly once. Tokenizing is a job of tens of values, not hundreds.
- **The cost is ambiguity, not volume.** 29 of the 78 client-facing colors serve more than one role,
  and the big ones are the worst offenders (counts across SCSS + React):

  | hex | text | background | border |
  |---|---|---|---|
  | `#181715` | 180 | 27 | 25 |
  | `#E5E6E4` | 2 | 19 | 118 |
  | `#261FFF` | 72 | 23 | 34 |
  | `#FFFFFF` | 65 | 64 | 11 |
  | `#847577` | 122 | 1 | 11 |

  A scripted `#181715 → var(--color-text)` is therefore wrong 52 times. Summed over every
  non-dominant role it is ~450 occurrences that need a human to decide which token applies — that
  number, not the 1,400 total, is what decides whether phase 2 takes two days or four.
- No theme / `prefers-color-scheme` / switcher exists. Two layouts (`application.html.haml`,
  `react_application.html.haml`) both load `application.scss` + the client bundle, so `:root` in the
  manifest reaches every page.
- Extras: inline colors in 12 HAML files; 30 of 32 icon SVGs carry a hardcoded `fill`/`stroke` and
  will not adapt on their own; club and national-team colors come from the DB (`club.color`, 16 call
  sites) and can only be contrast-checked, never tokenized; charts (tooltip/legend already on vars).

## Phases

**Phase 1 — Tokens. DONE 2026-10-09.** `app/assets/stylesheets/_theme.scss` holds 26 tokens at
`:root` (light = the current hexes) plus a `:root[data-theme="dark"]` block with the same 26. It is
imported first in `application.scss`, which both layouts load, so the tokens reach the HAML pages
and the React bundle alike. No `@media prefers-color-scheme` — light is the default.

Nothing consumes them yet and no element carries `data-theme`, so the change is inert by design:
the point was to land one place that answers "which green is our green". Verified in a browser that
all three states resolve (no attribute / `dark` / `light`) and that the dark block overrides.

Two things to know before phase 2:
- Tokens are named for ROLES, not hues, because a hue name cannot survive the override —
  `--color-surface-inverse` is near-black in light and near-white in dark. Each state ships as a
  trio: the strong colour, its `-soft` tint for fills, and the `-text` that goes on that tint.
- sassc rewrites `:root[data-theme='dark']` into `[data-theme='dark']:root`. Same specificity, same
  match — do not "fix" it.

**Phase 2 — Tokenize styles (bulk, client-facing only).** Replace hardcoded hex with `var(--…)`.
In scope: `teams, leagues, players, lineups, auctions, auction_bids, auction_rounds, tours,
tournament*, round_players, matches, substitutes, transfers, clubs, articles, links, national_teams,
footer, header, nav_panel, join, welcome, divisions, application` + React CSS modules. Out:
`manage, rails_admin/*, devise, scaffolds`, mailer.

Do it per property, never per hex: a script may rewrite `color: #181715` → `var(--color-text)` and
`border-color: #E5E6E4` → `var(--color-border)` safely, because those pairs are unambiguous. Every
occurrence where a dominant colour appears in its MINORITY role (the ~450 counted above) has to be
read and decided by hand — that is the whole risk in this phase. Largest files first:
`application.scss` (150 colours), `teams.scss` (106), `auction_rounds.scss` (100), `tours.scss` (98).

A cheaper stopping point, if dark theme is deferred: tokenize only the unambiguous dominant colours
and leave the rest as hex. That captures most of the reuse benefit for about a day and commits to
nothing.

**Phase 3 — Cookie + switcher (no FOUC).** `before_action` in `ApplicationController` reads cookie
`theme` → `%html{ 'data-theme': @theme }`. Switcher (existing `Switcher` component) in the nav; on
click sets the cookie (1y) + `document.documentElement.dataset.theme`.

**Phase 4 — Assets / edge cases.** Dark SVG logos/icons → `filter: invert()` under
`[data-theme="dark"]` or dark variants; field skeleton, avatars/kits, shadows/overlays, charts
(add dark values). Data-driven club colors: keep, check contrast. Tokenize the 14 inline HAML colors.

**Phase 5 — QA.** Both layouts + mobile header, light/dark, WCAG AA contrast, screenshot regression
via the WebKit/Playwright harness.

## Effort

Phase 1 ~0.5d — **spent, done**. Phase 2 is the bulk, ~2–4d, and the spread comes from the ~450
context-dependent occurrences rather than the line count. Phase 3 ~0.5–1d. Phases 4–5 ~1–2d
(30 of 32 icon SVGs need `currentColor`, dark variants or an `invert()` filter; the 15 `rgba()`
shadows are black and vanish on a dark ground). Total ~3.5–6.5 days remaining. Split into several
PRs: tokens → tokenization by file group → switcher → assets/QA.
