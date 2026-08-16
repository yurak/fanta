# Live Scores & Ratings Plan

Pull FotMob player ratings **and the match result in live mode** (poll every ~5 min while a match is
in progress) instead of only after the final whistle, and mark in-progress matches with a distinct
colour on the tour page.

**Applies to both sources** — the live path lives in `Scores::Injectors::BaseMatch`, so FotMob and
Sofascore both get it.

## Feasibility (verified)

The live data is **already in the payload the app parses** — the code just waits for full time.

- `Scores::Injectors::FotmobMatch` scrapes the match page (`__NEXT_DATA__`) and reads
  `status.started`, `status.finished`, `status.scoreStr` and per-player `rating` / `played_minutes`.
  FotMob serves all of this **during** the match (that is why `players_data_ready?` checks
  `played_minutes > 0`).
- `Scores::Injectors::BaseMatch#call` is the only blocker:
  ```ruby
  return unless match.page_url
  return unless match_finished?      # started && finished  <-- gates everything on full time
  return unless players_data_ready?
  match.update(host_score:, guest_score:)   # match result
  update_round_players                      # player ratings
  audit_missed_players(...)                 # CSV audit
  ```

### Access constraints (checked from the prod server, IP 3.250.107.9)

FotMob blocks our server IP on the whole JSON API — verified:

| Endpoint | From server |
|---|---|
| `GET /api/matchDetails?matchId=…` | **404**, returns HTML shell (not JSON) |
| `GET /api/leagues?id=47` (plain + browser UA) | **404**, HTML shell |
| `GET /matches/…` (page scrape) | **200** ✅ |

So the **match-page scrape is the only working source**, and it already carries status + score +
ratings in one request. (`TournamentRounds::FotmobParser`, which uses the leagues API, is unused for
~1 year — ignore it.) Re-check anytime, from the server (blocking is per-IP):

```
ssh -i ~/.ssh/mantrakey.pem ubuntu@3.250.107.9 \
  'curl -s -o /dev/null -w "%{http_code}\n" "https://www.fotmob.com/api/matchDetails?matchId=5795807"'
# 200 + JSON = unblocked; 404/HTML = still closed
```

## Current behaviour to preserve

- **Score injection**: `Scores::Injectors::{Fotmob,Sofascore}.call(tournament_round)` → per match →
  `*Match.call` (`BaseMatch`). Writes `TournamentMatch#host_score/guest_score`, updates each
  `RoundPlayer` (rating, goals, assists, cleansheet, cards, saves, penalties, `played_minutes`,
  `in_squad`), then `audit_missed_players` (writes `missed_players_data` + CSV).
- **`manual_lock`** round players keep their score source but only `{ score, in_squad }` is touched
  (`BaseMatch#round_player_params`) — must stay.
- **Scheduling today**: `whenever` (`config/schedule.rb`) runs `tours:auto_inject` hourly at `:55`,
  and `Tours::AutoInjector` only injects at `INJECT_AT_HOURS = [6, 12, 17]` hours after moderation.
  No live path exists.
- **Fantasy recompute**: after injection `Tours::AutoInjector#update_tours` runs
  `Scores::PositionMalus::Updater` + `Lineups::Updater` per tour.
- **Models**: `TournamentMatch` / `NationalMatch` have `host_score`, `guest_score`, `page_url`,
  `date`, `time` (+ `utc_datetime`), `source_match_id` — but **no live/finished state**. Score
  presence cannot distinguish live vs final (a score exists in both).
- **Tour rendering**: `tours/show.html.haml → _round_matches` → `tours/_fanta_round.html.haml` →
  `tournaments/_tournament_matches.html.haml` / `_national_matches`. Each cell shows
  `host_score:guest_score` when a score exists, else the kickoff time.

## Design

### 1. Persist match state (migration)

Add to `tournament_matches` and `national_matches`:

- `status` (enum-backed integer, default `scheduled`): `scheduled` / `live` / `finished`, **or** a
  simpler `finished:boolean` + `live:boolean`. Enum preferred.
- (optional) `started_at:datetime` and a `live_minute:integer` for a "45’" badge if the payload
  exposes it (confirm the field on a live match).

Set from the scraped `status` on every injector pass. This drives the tour colour and lets the
scheduler pick who to poll without re-scraping.

### 2. Live branch in the injector

In `Scores::Injectors::BaseMatch#call`, allow a live pass:

- Run when `started && !finished && players_data_ready?` **or** when `finished` (final, authoritative).
- On every pass: update `host_score/guest_score` and `update_round_players` (idempotent refresh —
  ratings just get the latest value).
- **Only on `finished`**: `audit_missed_players` + set `status: :finished`. During live, a player not
  yet subbed on has no data and would be falsely flagged as "missed", and the CSV write should not
  run every 5 min.
- Set `status: :live` on a live pass.
- Keep `correct_round?` and `manual_lock` handling unchanged.
- Provisional live ratings/cleansheet flip as the match evolves (0-0 CS disappears after a goal) —
  expected; each pass recomputes.

Add a `live?`/`match_finished?` split in `FotmobMatch` (and `SofascoreMatch`) and a `run_mode`
(`:live` / `:final`) argument threaded from the caller.

### 3. Scheduler (poll only live candidates)

New rake task (e.g. `tours:live_inject`) + `config/schedule.rb`:

```ruby
every 5.minutes do
  rake 'tours:live_inject'
end
```

The task selects **only plausibly-live matches** from the DB — `utc_datetime` within the last
~2.5 h and `status != finished` — and scrapes just those pages (never all matches). For each affected
tour, re-run `Scores::PositionMalus::Updater` + `Lineups::Updater` so fantasy points update live.

Scoping keeps scrape volume tiny: a typical round has 1–4 concurrent live matches → a few requests
per 5 min.

### 4. Scrape resilience

FotMob is clearly tightening (whole JSON API now 404s). Harden the page scrape:

- Retry with backoff (mirror `Players::Transfermarkt::RetriableApi`), realistic `User-Agent`.
- **Graceful skip** on 403/429/challenge: keep the last stored value, do not blank scores/ratings.
- Log/alert when the page scrape starts failing so a block is noticed early.

### 5. Tour page colour

In `tournaments/_tournament_matches.html.haml` and `_national_matches`, add a CSS class when
`match.live?` (e.g. `.round-tournament-match--live`) around the result cell; style in the tour SCSS.
Optionally show the live minute if captured.

## Rollout

- **Feature flag** (per-tournament or global config) so live mode can be enabled for one league first.
- **Phase 1**: migration + live branch + `tours:live_inject` (flag off) — verify on one live match
  that scores/ratings refresh and `status` flips scheduled→live→finished.
- **Phase 2**: enable fantasy recompute in the loop + the tour colour.
- **Phase 3**: enable the flag broadly; keep the existing hourly `tours:auto_inject` as the
  authoritative final pass (belt-and-braces).

## Effort & risks

- ~2–4 days: 1 migration, injector live branch, 1 scoped rake task + schedule line, small view/CSS,
  specs (live vs final pass, `manual_lock` preserved, audit-only-on-final, candidate selection).
- **Main risk: scrape stability.** The JSON API is already blocked; the HTML page could follow
  (Cloudflare challenge). Mitigate with backoff + graceful-skip + alerting; the feature degrades to
  "final only" if scraping breaks, i.e. no worse than today.
- Secondary: users see fluctuating provisional scores in live mode — acceptable, but signal it in the
  UI (the live colour doubles as "provisional").

## Verify on a live match (before shipping)

Confirm on a real in-progress match that the scraped `__NEXT_DATA__` populates `status.scoreStr`,
per-player `rating`/`played_minutes`, and ideally a live-minute field — then wire the `live_minute`
badge only if present.
