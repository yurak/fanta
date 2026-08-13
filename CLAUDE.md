# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

MantraFootball ("fanta") — a fantasy football app. Ruby on Rails (Rails 8, Ruby 3.2) with a
React front-end (react_on_rails + shakapacker), PostgreSQL. Tests: RSpec. Linting: RuboCop.

## Backlog

The feature backlog lives in [docs/BACKLOG.md](docs/BACKLOG.md) — read it for planned work and
priorities. Keep only planned/unfinished items: when a feature is finished, DELETE it from the
file (do not keep a "done" section).

## Conventions

Whenever you discover a non-obvious project rule, gotcha, or preferred pattern while working,
append it to this list so future sessions don't rediscover it. Keep entries short and specific.

- NEVER run `git commit` or `git push` — the user commits and pushes themselves.
- Run the test suite and full RuboCop after each task; both must be green.
- i18n: edit `config/locales/{en,ua}.yml`, then run `bundle exec i18n export` to regenerate
  `app/client/locales/locales.json` (it is generated — do not edit it by hand).
- Bootstrap 4 in manage/legacy views: use `mr-*`/`ml-*` (not `me-*`/`ms-*`), no `gap-*` utility.
- Resolve a club by its Transfermarkt id via `Club.for_tm_id(tm_id)` (do NOT name such helpers
  `find_by_*` — RuboCop's Rails/DynamicFindBy rewrites the calls to `find_by`).
- Transfermarkt deletes transfer rows it later considers wrong (e.g. a "Without Club" contract-expiry
  entry once the player re-signs), so `ClubTransfers::HistoryImporter` must prune stored tm-sourced
  transfers TM no longer lists — a leftover row stays the newest one and silently blocks all further
  `ClubTransferRequest`s for that player.
- A team is reused across seasons, so it has MANY joins (`Team has_many :joins`). Never look up
  "the" join by team — scope by season (`Join.current_season`) or go through the auction bid
  (`AuctionBid#join`). Same for admin lists: `Join.pending` alone leaks past-season leftovers.
- Creating `ClubTransferRequest`s by hand (TM down / move not on TM yet): follow
  [docs/MANUAL_CLUB_TRANSFERS.md](docs/MANUAL_CLUB_TRANSFERS.md) — console helper, lookup snippets and
  the gotchas (leave `tm_transfer_id` nil; confirm in the UI, never by flipping `status`).
- TM's JSON API (`tmapi-alpha.transfermarkt.technology`) is being decommissioned and breaks in new
  ways (dead DNS, refused TLS handshake). `ApiParser`/`ClubSquadParser` therefore fall back to
  `PlayerHtmlParser`/`ClubSquadHtmlParser`, which scrape `www.transfermarkt.com` — the host the
  working `ceapi/*` endpoints already use. `RetriableApi` fails fast (no 10/20/30s sleeps) on DNS
  and TLS-alert errors so the fallback kicks in immediately.
- Player `name` is the SURNAME only (`first_name` holds the given name) and accents are stripped
  (`Núñez` → `Nunez`), so search players by ASCII surname and disambiguate on `first_name`/`birth_date`.
- An `AuctionRound` stays `active` until the cron job (`auction_rounds:process`, every 2 min) picks it
  up, so the *deadline* — not the status — is what closes it for bidders: gate writes on
  `AuctionRound#editable?`, never on `active?`. The same cron overlap is why `AuctionRounds::Manager`
  takes `round.lock!` + re-checks `active?` inside its transaction: `process_auction` →
  `AuctionRounds::Creator` is NOT idempotent and a second pass builds a duplicate next round.
- Over-budget bids are trimmed (biggest bid first, down to `player.stats_price`, cascading to the next
  one) ONLY in the first stage of the primary auction; every other round drops such a bid whole.
- `Results::Updater`/`FantaUpdater` write results through *separate* queries (`by_team(...).last`,
  `find_or_create_by`), so anything they later read must come from a fresh relation — never from
  `league.results`. `has_many :tours, inverse_of: :league` makes `tour.league` the caller's League
  object, so a preloaded association (e.g. `manage#refresh` doing `league.results.each(&:reset_stats)`)
  leaks stale zeros into `history` while the table columns stay correct.
