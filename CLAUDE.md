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
- The React app persists react-query results to `localStorage` (`app/client/bootstrap/useQueryClient.ts`,
  `maxAge` 1 day), busted ONLY when `buster: packageJson.version` changes. So whenever you change the
  SHAPE of any `/api/*` JSON response (add/rename a field the client reads), BUMP `version` in
  `package.json` — otherwise a full reload keeps serving the stale cached payload (missing the new
  field) for up to a day, and the change silently doesn't take effect in the browser.
- Live scores are FotMob-only, gated by `Tournament#live_scores_enabled` (toggle in the manage module,
  NOT rails_admin). Matches are played while a tour is `locked` OR `postponed` (a rescheduled tour stays
  `postponed`, never re-locked — mirror the app-wide `locked_or_postponed?`), so BOTH count: `live_inject`
  polls `locked`+`postponed` rounds (`LIVE_TOUR_STATUSES`), and `refresh_schedule` re-pulls kickoff times
  daily for `set_lineup`+`locked`+`postponed` rounds (`SCHEDULE_TOUR_STATUSES`, skips finished matches),
  so a reschedule after lock is still picked up. FotMob's JSON API is IP-blocked — only the match-page
  HTML scrape (`#__NEXT_DATA__`) works.
- FotMob withholds `played_minutes` during a live match (streams ratings only), so the live pass gates
  on ratings (`players_data_ready?`), forces `played_minutes: 0`, and defers cleansheet to the final
  pass. Partial-appearance cleansheet (60–89') is computed from FotMob goal + substitution minutes
  (`cleansheet?`/`no_goals_while_on_pitch?`): a player keeps it if the team conceded only while he was
  off the pitch. The live pass never blanks stored scores, and `manual_lock` on a round_player preserves
  manually-set stats (incl. cleansheet).
- A live `TournamentMatch`/`NationalMatch` must be driven to `finished` by CONTINUED live polling, so
  `LiveInjector#within_window?` returns true for any `live?` match regardless of kickoff — gating live
  polling on the kickoff window alone leaves a match stuck `live` forever if a pass misses full time.
- Manage edit forms submit EVERY field, so an empty text input saves `''` (not `nil`) over a previously
  nil column — and `a || b` / `a ?? b` fallbacks then render the blank. Normalize such columns in the
  model (`normalizes :short_name, with: ->(v) { v.strip.presence }`) rather than patching call sites.
- FotMob counts a penalty goal in BOTH the scorer's `Goals` and the keeper's `Goals conceded`, and it never
  sends `Penalty goals conceded` (0 hits across 51 keeper stat blocks) — so penalties must come from the goal
  EVENTS: the scorer's is moved `goals` → `scored_penalty`, the keeper's `Goals conceded` → `missed_penalty`
  via the on-pitch window (`sub_in`/`sub_out`), never counted twice. `conceded_penalty` is a different stat
  (the player fouled and gave a penalty away, the mirror of `penalties_won`) — don't conflate the two.
  Always skip `isPenaltyShootoutEvent`: a shootout kick is not a goal and would otherwise drive `goals` negative.
