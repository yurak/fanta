# Feature Backlog

> Portable backlog kept in the repo so Claude Code can work with it on any machine after `git clone`.

## Prioritized (has a plan)

1. **Ruby & Rails Upgrade** (Ruby 3.2.2 → 4.x)
   Rails side is already in production (Rails 8). Remaining: Ruby 3.4 → Ruby 4.x → cleanup.

2. **Viewport Migration** (mobile-first)
   8 stages, not started. Scope: legacy haml on the `application` layout (React pages are already device-width).

3. **Token auth + Flutter app v1** — see [MOBILE_APP_PLAN.md](MOBILE_APP_PLAN.md)
   Not started. `devise-jwt` + closing the anonymous `/api` (the two are one edit), then a read-only
   companion app on the endpoints that already exist. Closing the API puts `/players` behind login.

4. **Dark theme** — see [DARK_THEME_PLAN.md](DARK_THEME_PLAN.md)
   Not started. Client-facing only (public pages + SPA; not manage/admin/email). Light default,
   dark opt-in via a cookie-persisted toggle. Colors are hardcoded hex today → build a `:root` token
   layer first, then tokenize ~17.9k lines of SCSS. ~4–7 days, several PRs.

**Core-loop React migration (items 5–9, do in this order).** API-first each time (JSON endpoints
reused by the mobile app); ship behind SPA routes with HAML fallback + a parity cutover; retire HAML
and drop the page from Viewport Migration once verified. Read-mostly pages (match/team/tour) are
lower-risk early wins; the write-critical/real-time ones (lineup, auction) bookend the sequence.

5. **Lineup builder → React (API-first)** — see [LINEUP_BUILDER_REACT_PLAN.md](LINEUP_BUILDER_REACT_PLAN.md)
   Not started. Rewrite the lineup create/edit page (today a ~350-line inline jQuery block in HAML)
   as a React feature. API-first: JSON endpoints for candidates + save (`Lineups::Validator` shared),
   then the React builder, then a parity cutover. Multi-week epic; overlaps the token-auth/`/api` item.
   Proves the API-first pattern for the rest of the sequence.

6. **Match page → React** — see [MATCH_PAGE_REACT_PLAN.md](MATCH_PAGE_REACT_PLAN.md)
   Not started. Read-mostly, high-frequency → best value/effort. Home for the *"Player form on the
   match page"* item (reuse the form-strip component). ~1 week, low regression risk.

7. **Manager team page → React** — see [TEAM_PAGE_REACT_PLAN.md](TEAM_PAGE_REACT_PLAN.md)
   Not started. The manager's hub (matches / transfers / squad tabs). Read-mostly. ~1 week.

8. **Tour (round) page → React** — see [TOUR_PAGE_REACT_PLAN.md](TOUR_PAGE_REACT_PLAN.md)
   Not started. The round hub; main win is SPA cohesion (seamless tour → match → lineup navigation).
   Do after match + lineup so nav targets are already React. ~1 week (less if RoundPlayers/Players
   React components are reused for the stat tabs).

9. **Auction → React** — see [AUCTION_REACT_PLAN.md](AUCTION_REACT_PLAN.md)
   Not started. Highest value (real-time bidding, heaviest jQuery — `_bid_block` ~650 lines) but
   highest risk (real-time + money/squad-critical) → do LAST. Polling first, WebSocket later.
   ~2–3 weeks; server-authoritative bid validation + a live parity dry-run are mandatory.

## No detailed plan yet

- **Rework of the drop / out-transfers pages** — UI redesign.
- **Player statuses** (injury / suspension / doubtful) shown when setting a lineup.
- **xPoints after tour close** — expected points of a squad, computed after `tour.close!`.
- **Player wishlists** (watchlist) — save players into watch lists. Basis for auto-bidding in the 2nd+ auction.
- **Player form** on the match page (last N matches / ratings).
- **Auto-bid in 2nd+ auction** from the wishlist _(depends on wishlists)_.
- **Reorder the user's teams** — in user settings, let the user drag-and-drop their list of teams to
  set a custom order; persist it and render the teams in that order in the left-nav menu.
- **Update npm packages** — react-select 5→6, rc-slider 10→11, chart.js 4→5, @floating-ui/react 0.26→1.x, etc.
