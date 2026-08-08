# Auction → React (API-first) Plan

Rewrite the auction flow (`app/views/auction_bids/_bid_block.html.haml` — **~650 lines** — plus
`auction_bids/show`, `_stats_section`, `auction_rounds/show`, `auctions/live`, `auctions/_logs`,
`auctions/show`) as a React feature.

**Sequence: step 5 — LAST.** Highest value (most interactive, real-time, highest-stakes part of the
app) but highest risk (real-time + write-critical). Do it only after the API-first pattern and the
JSON auth story are proven on lineup / match / team / tour.

## Why this page — and why last

The auction is real-time bidding: the heaviest jQuery in the codebase (`_bid_block` alone is ~650
lines with AJAX search, bid submission, and `location.reload()` on change), plus `auctions/live`
polls with `setInterval`. React replaces polling-and-reload with managed live state and optimistic
bids. But it is money/squad-critical and real-time, so it carries the most regression risk — hence
last, once the patterns are settled.

## Current behaviour to preserve (parity checklist)

- **Bid block** (`_bid_block`): search players (debounced AJAX), place/raise a bid, current-bid
  display, refresh, `location.reload()` after actions; bid validation.
- **Live view** (`auctions/live`): `setInterval` polling of auction state; live standings/current
  lot; admin-gated (`can? :live`).
- **Logs** (`_logs`): live bid history/feed.
- **Auction rounds** (`auction_rounds/show`): round state, transfers in / drop-outs (top-5),
  modules.
- **Stats sections** (`_stats_section`): per-auction/bid stats.
- **Roles**: bidder vs admin/live; transfer-auction vs initial auction (`@is_transfer_auction`).
- **Services already in place**: `Auctions::Manager`, `PlayerBids::Search`, `AuctionBid`,
  `auction_transfers` — reuse as the API layer.

## API design (Phase 1)

- `GET /api/auctions/:id/state` → JSON snapshot: current lot/bid, standings, round state, timers,
  role flags. This is the **live** endpoint.
- `GET /api/auctions/:id/players?search=` → JSON candidate search (wrap `PlayerBids::Search` /
  `Player.by_tournament.search_by_name`).
- `POST /api/auction_bids` / `PATCH /api/auction_bids/:id` → place/raise a bid; server is
  authoritative on validation, budget, and race conditions; returns the new state.
- `GET /api/auctions/:id/logs?since=` → incremental bid feed.
- **Live transport**: start with **polling** the `state`/`logs` endpoints (mirrors today's
  `setInterval`), designed so it can later upgrade to **ActionCable/WebSocket** without changing the
  component API. Concurrency/race safety on bids must live server-side (lock + validate).

## Frontend architecture (Phase 2)

- Routes in `App.tsx`: `/leagues/:leagueId/auctions/:auctionId` and `/auction_rounds/:id`,
  `/auction_bids/:id`.
- `app/client/pages/Auction/` with: `AuctionLive` (state poller + standings + current lot),
  `BidBlock` (search + place/raise, optimistic + reconciled with server state), `BidLogs` (feed),
  `AuctionStats`, `RoundSummary` (transfers in / drop-outs). Reuse `ui/` (Search, Table, Drawer).
- **State**: a single live-state store fed by the poller; bids are optimistic then reconciled;
  replace every `location.reload()` with state updates.

## Rollout (Phase 3)

- Ship behind the SPA routes with the HAML flow as fallback; **run a live auction in parity/staging
  first** — this is the riskiest cutover.
- Heavy testing: bid validation, budget limits, race conditions (two bidders), transfer vs initial
  auction, admin live view. API request specs + component tests + a concurrency test on bids.
- Only after a real auction runs clean, retire the HAML.

## Effort & risks

- The largest of the five — ~2–3 weeks (real-time + write-critical + many roles/variants).
- Highest regression risk: money/squad correctness and bid race conditions. Server-authoritative
  validation and a parity dry-run on a live auction are mandatory. Keep polling first; WebSocket is a
  follow-up optimization, not a prerequisite.
