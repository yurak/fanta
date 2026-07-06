# Feature Backlog

> Portable backlog kept in the repo so Claude Code can work with it on any machine after `git clone`.

## Prioritized (has a plan)

1. **Ruby & Rails Upgrade** (Ruby 3.2.2 → 4.x)
   Rails side is already in production (Rails 8). Remaining: Ruby 3.4 → Ruby 4.x → cleanup.

2. **Viewport Migration** (mobile-first)
   8 stages, not started. Scope: legacy haml on the `application` layout (React pages are already device-width).

## No detailed plan yet

- **Player wishlists** (watchlist) — save players into watch lists. Basis for auto-bidding in the 2nd+ auction.
- **xPoints after tour close** — expected points of a squad, computed after `tour.close!`.
- **Player statuses** (injury / suspension / doubtful) shown when setting a lineup.
- **Leaderboard** — manager rankings (scope: league / tournament / global — TBD).
- **Player form** on the match page and in the lineup builder (last N matches / ratings).
- **Auto-bid in 2nd+ auction** from the wishlist _(depends on wishlists)_.
- **Rework of the drop / out-transfers pages** — UI redesign.
- **Update npm packages** — react-select 5→6, rc-slider 10→11, chart.js 4→5, @floating-ui/react 0.26→1.x, etc.
- **Season switcher** on the global players page.
