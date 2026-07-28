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
- A team is reused across seasons, so it has MANY joins (`Team has_many :joins`). Never look up
  "the" join by team — scope by season (`Join.current_season`) or go through the auction bid
  (`AuctionBid#join`). Same for admin lists: `Join.pending` alone leaks past-season leftovers.
