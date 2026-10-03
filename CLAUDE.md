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
- When TM blocks the SERVER's IP (CloudFront `HTTP 405` from EC2) but not yours, don't fall back to
  hand-made requests: run the import locally, copy `tmp/transfermarkt_cache` into the prod release and
  re-run it there — `TransferHistoryParser` then reads the cache and never calls TM. `TM_SKIP_CACHE`
  must NOT be set on the prod side (it disables the cache read), and the cache is stale after 7 days.
  See [docs/MANUAL_CLUB_TRANSFERS.md](docs/MANUAL_CLUB_TRANSFERS.md).
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
- A `RoundPlayer` is identified by (`tournament_round`, `player`) ONLY — `club_id` is an attribute, never
  part of the lookup. Create/fetch one through `RoundPlayer.for_round`, which realigns the club when the
  player has transferred; a `find_or_create_by(..., club:)` spawns a SECOND row for the same round, and the
  injector (whose `by_club` filters on `players.club_id`, the player's CURRENT club) then feeds whichever
  row Postgres hands back first, so lineups on the other one silently show 0 and the autobot substitutes a
  player who actually played — and `missed_players` stays empty, because the source entry WAS consumed.
  A unique index enforces this; keep the injector on `players.club_id` (thousands of rows have a stale
  `round_players.club_id`, and 373k older ones have none at all).
- A relation without `ORDER BY` comes back in Postgres HEAP order, and every score injection UPDATEs the row,
  which moves it — so a re-injected round jumps position. Any list a user reads must be ordered explicitly
  (`RoundPlayer.chronological` for the per-round tables on the player page); reversing an unordered relation
  in a serializer is not an order.
- Specs must not build an expectation out of a generated name: FFaker surnames and company names carry
  an apostrophe ~2% of the time, and anything that transforms the string (`CGI.escapeHTML` → `&#39;`,
  `Player#path_name` deleting it, HTML escaping in a rendered view) then makes the example fail on
  roughly one CI run in forty. Pin the name in the fixture, or compare against the transformed form.
- Telegram messages that hide a URL behind a call to action go out with `parse_mode: 'HTML'`, and then
  an unescaped `&` in a league or team name ("Bravery&Stupidity") is a 400 from the API — the user
  never receives that notification. Build such a message through `TelegramBot::HtmlMessage#html_message`,
  which escapes every interpolation, and send it with `send_html`; never call `I18n.t` + `Sender` directly.
- `Players::Manager` only refuses an unknown club when UPDATING (there it would move a real player to
  Outside on a club name we failed to resolve). CREATE must fall back to Outside instead — most players
  we add by TM id play at clubs we do not carry (lower divisions, reserve sides), and the old
  `return false unless club || national_team` made the manage page answer "Failed to create player"
  for every one of them. `club_id` already had the Outside fallback; the guard was what blocked it.
- `I18n.transliterate` has no rule for the Romanian comma-below letters (`ț` U+021B, `ș` U+0219 — a
  different codepoint from the cedilla forms it knows) and turns them into `?`, so "Moruțan" was stored
  as "Moru?an". Normalise player names through `Players::Transfermarkt::NameNormalizer#normalize_name`,
  which decomposes (NFD) and drops combining marks before transliterating.
- Never render an image with `<object data=...>`, and never name a class after ad/social vocabulary.
  Both are blocked client-side and neither shows up in our logs: an `<object>` is plugin content, which
  NoScript-style extensions refuse by default and any `object-src` CSP kills outright (the commented-out
  `policy.object_src(*aws_urls)` in `content_security_policy.rb` is the scar), and Fanboy's Social list
  carries the generic cosmetic rule `##.footer-social`, which hid the footer icons for everyone running
  it. Use `<img>` with an `onerror`/`onError` fallback (`ClubLogo` wraps the club-crest case). Before
  naming a class, check it against a filter list — `.footer-follow` is blocked too; `.footer-contacts`
  is not. The image URLs themselves are clean: no rule in EasyList/EasyPrivacy/Fanboy Social/uBO
  matches any avatar, kit or crest path, so a blocked image is a markup or class-name problem.
- SofaScore rounds a cameo shorter than a minute down to `minutesPlayed: 0` and then sends no rating
  with it, so `SofascoreMatch#build_players_hash` used to drop that player before any scoring ran: he
  reached us with no score, no card and `in_squad` only. Derive his minutes from the substitution
  events instead (`played_minutes_for`), taking the end of the spell from a red card when he never
  came off. A card alone is NOT proof of playing — a substitute can be sent off from the bench — so
  the substitution-in event is what admits him. A STARTER has no such event: his ticket is a red card
  or being taken off, and without one he stays at nought, because an unconfirmed lineup is a list of
  predicted starters and a full match each would invent minutes and a default score.
- `MatchPlayer#not_played?` drives the autobot, and it must weigh minutes as well as the score
  (`score.zero? && played_minutes.to_i.zero?`). On score alone, any player a source reports without a
  rating is replaced in every lineup he is in, even though he was on the pitch.
- `RoundPlayer#related_club` prefers the club stored on the round player over the player's own, and
  `MatchPlayer#kit_path` goes through it — so `round_player: [:club]` must stay in MatchPlayer's
  `default_scope` includes. Without it a lineup fires one `clubs` SELECT per player (33 queries for a
  39-man lineup instead of 7) while the batched `players.club` preload sits unused.
- The autobot's two passes are a plan and its execution, not two computations. `AutoBot` with
  `preview: true` stores the pairs as `{out_mp_id, in_mp_id, out, in}` in `lineups.substitutes`, and
  the apply pass carries THAT plan out — scores keep arriving between the admin's two clicks, and
  recomputing would perform swaps nobody approved. Both passes write the record, so applying without
  a preview still leaves a trace; a pair that no longer validates is logged as `[autobot] skipped`.
  Do not add a `subs_missed?` gate before calling it: that reloads every match player of the lineup
  only to decide whether to load them again, and `AutoBot` already no-ops when there is nobody to
  bring on.
- Squad lists for a national-team tournament live in `config/mantra/national_squads/<window>.csv`, and
  `rake 'national_squads:check'` diffs them against what Wikipedia lists now (newest CSV by default,
  `check[file.csv]` for a particular one). It is written for ANY such tournament — only the CSV is
  tied to one window. Three traps are already encoded in `NationalSquads::WikiParser`, each learned
  the hard way: `{{nat fs r player}}` is the "Recent call-ups" table and is NOT the squad;
  `{{nat fs break}}` only splits columns, so it cannot end the table; and template names appear both
  capitalised and not. `NationalSquads::Comparer` pairs names one-to-one — a shared given name would
  otherwise absorb two people and hide a swap behind an unchanged head count — and its `ALIASES` hold
  nickname pairs (Rodrigo Hernandez ↔ Rodri). Transliteration differences belong in the normaliser,
  never in ALIASES.
- Adding a tournament is a DATA job, not a code one: `config/mantra/tournaments.yml` and `clubs.yml`
  are read only by `db:seed` and are 15 tournaments behind production. The cron rakes are generic
  (`standings:refresh` takes every tournament with a `source_id`; `tours:live_inject` /
  `refresh_schedule` every one with `live_scores_enabled`), the calendar import is a manage-UI button
  driven by `source_id`, and `Tournament#logo_path` falls back to `uefa.png`. The one MANDATORY edit is
  `config/mantra/auctions_calendar.yml`: `Leagues::Activator#base_auctions_dates` does
  `YAML.load_file(...)[tournament.code]` and then `.last(n)` on it, so a code missing from that file is
  a `NoMethodError` the moment an admin activates the first league. Then the logo
  (`app/assets/images/tournaments/<code>.png` — `image_tag` on a missing asset takes the fees page
  down), the `welcome.fee.tournament.<code>` locales and a `.type-league` block in
  `welcome/fees.html.haml`. `sofa_number` and `source_calendar_url` are display-only leftovers.
  A club's `name` (or `full_name`) must be FotMob's spelling — `TournamentMatches::CalendarImporter`
  resolves clubs by those two columns — and `fotmob_id` must be set or `Standings::Updater` cannot
  place the club in the table. A new tournament prices every player at 1, because `Player#stats_price`
  scopes last season's `player_season_stats` to `club.tournament`; Turkey shipped that way.
- `clubs.tm_name` is legacy and must NOT be filled in for new clubs. It once verified a player's club
  against the name on his Transfermarkt page; that check now goes by the TM club id
  (`Club.for_tm_id`, which reads `tm_url`), so the column survives only as a display row on
  `manage/clubs/show`. A blank `tm_name` is the correct state, not a gap. `clubs.full_name` IS still
  functional: `TournamentMatches::CalendarImporter#club` resolves a club as
  `find_by(name:) || find_by(full_name:)`, so it is needed only where FotMob spells the club
  differently from our `name` (Leicester -> "Leicester City", Plymouth -> "Plymouth Argyle").
- `Tournament#skip_round_check` must be ON for any competition whose source numbers rounds per group
  rather than per calendar window — every national-team tournament, in practice. FotMob reports
  `general.leagueRoundName` as that group's matchday, so a team playing its first group game in our
  round 2 comes back as "1", `Scores::Injectors::FotmobMatch#correct_round?` returns false, and the
  live pass writes nothing. The failure is silent and reads like success: `correct_round?` also feeds
  `match_live?`, and `players_data_ready?` only accepts ratings while the match counts as live —
  otherwise it demands `played_minutes`, which FotMob withholds mid-match. So `match_writable?` is
  false, no score and no status reach the record, and `Tours::LiveInjector` still reports
  `with_data: 1, failures: 0` because the data did arrive, it just was not written. It is on for the
  World Cup, Champions League, Europa League and USA; the Nations League ran a whole round without
  live scores before it was switched on, and Euro, Africa Cup and Club World Cup still lack it.
