# Dark Theme Plan

Plan for adding a site dark theme. Decisions locked (2026-08-08):

- **Default**: light; dark is opt-in via a toggle (no auto `prefers-color-scheme`).
- **Persistence**: cookie (`theme`), read server-side so `<html data-theme>` is set before first byte → no FOUC.
- **Scope**: client-facing only — public pages + React SPA. **Out of scope**: `manage`, `rails_admin`, `devise`, mailer/email templates.

## Current state (audit)

- **Server-side (Rails)**: 33 SCSS files, ~17.9k lines, colors hardcoded as hex — 0 SCSS variables,
  0 CSS custom properties at `:root`. ~86 distinct hexes, but a narrow core dominates: `#181715`
  (text/bg, 165×), `#E5E6E4` (borders), `#847577` (muted text), `#261FFF` (brand), `#FFFFFF`,
  `#F4F4F4`, … — ~15–20 colors cover nearly everything.
- **React**: CSS modules (scoped); some UI components already use `var(--…)`, but only as
  component-local vars — no central tokens, no `:root`.
- No theme / `prefers-color-scheme` / switcher exists. Two layouts (`application.html.haml`,
  `react_application.html.haml`) both load `application.scss` + the client bundle.
- Extras: 14 inline colors in HAML, 123 SVGs (some dark logos/icons that won't adapt on their own),
  charts (Chart tooltip/legend already on vars).

## Phases

**Phase 1 — Tokens.** `app/assets/stylesheets/_theme.scss` with `:root { --bg; --surface; --text;
--text-muted; --border; --brand; --brand-contrast; --danger; --success; --warning; … }` (light =
current hexes) and a `:root[data-theme="dark"]` override. No `@media prefers-color-scheme` (light is
default). Wire into both layouts globally.

**Phase 2 — Tokenize styles (bulk, client-facing only).** Replace hardcoded hex with `var(--…)`.
In scope: `teams, leagues, players, lineups, auctions, auction_bids, auction_rounds, tours,
tournament*, round_players, matches, substitutes, transfers, clubs, articles, links, national_teams,
footer, header, nav_panel, join, welcome, divisions, application` + React CSS modules. Out:
`manage, rails_admin/*, devise, scaffolds`, mailer. Script the ~15 dominant colors, then a manual
pass for context-dependent uses (same hex as text vs bg → different tokens).

**Phase 3 — Cookie + switcher (no FOUC).** `before_action` in `ApplicationController` reads cookie
`theme` → `%html{ 'data-theme': @theme }`. Switcher (existing `Switcher` component) in the nav; on
click sets the cookie (1y) + `document.documentElement.dataset.theme`.

**Phase 4 — Assets / edge cases.** Dark SVG logos/icons → `filter: invert()` under
`[data-theme="dark"]` or dark variants; field skeleton, avatars/kits, shadows/overlays, charts
(add dark values). Data-driven club colors: keep, check contrast. Tokenize the 14 inline HAML colors.

**Phase 5 — QA.** Both layouts + mobile header, light/dark, WCAG AA contrast, screenshot regression
via the WebKit/Playwright harness.

## Effort

Phase 1 ~0.5d. Phase 2 is the bulk, ~2–4d (17.9k lines, manual screen checks). Phase 3 ~0.5–1d.
Phases 4–5 ~1–2d. Total ~4–7 days. Split into several PRs: tokens → tokenization by file group →
switcher → assets/QA.
