# Plan: Token Auth + Flutter App v1

> Self-contained handoff. Everything needed to start is in this file — no external context required.
> Written 2026-07-29 against branch `staging` @ `0c256dcd`.
> Revised 2026-08-01 against `staging` @ `b10f6dc`: the Leaderboard feature (#549) merged after the
> first draft — it adds a **public** `api/leaderboard#index`, accounted for below.
>
> **Decision (2026-08-01): build a native Flutter app.** A PWA over the existing React SPA was
> weighed as the cheaper read-only path and rejected — see B0.
>
> **Nothing here is implemented yet.** All file references below describe the *current* state.
> Verify them before acting — this document ages, the code moves.

## Goal

Two linked pieces of work:

1. **Token authentication** for the Rails API, so a mobile client can authenticate without session cookies.
2. **Flutter app v1** — a read-only companion app built on the endpoints that already exist.

---

## Current state (verified 2026-07-29)

### The API is fully anonymous

`app/controllers/api/application_controller.rb:3` declares `before_action :authenticate_user!`, but
every concrete API controller skips it:

| Controller | Skipped actions |
|---|---|
| `api/results_controller.rb` | `index` |
| `api/player_bids_controller.rb` | `show` |
| `api/leagues_controller.rb` | `index`, `show` |
| `api/teams_controller.rb` | `index`, `show` |
| `api/seasons_controller.rb` | `index` |
| `api/tournaments_controller.rb` | `index` |
| `api/round_players_controller.rb` | `index`, `meta` |
| `api/players_controller.rb` | `index`, `show`, `stats`, `stats_export` |
| `api/divisions_controller.rb` | `index` |
| `api/leaderboard_controller.rb` | `index` — **merged in #549 after the first draft** |

`rack-cors` is not installed, so browsers block cross-origin JS reads — but server-side scraping
(`curl`, scripts) is unrestricted. `GET /api/players/stats_export` returns a whole season of player
stats as CSV, anonymously.

### The API is read-only

Routes live in `config/routes.rb:177`. The `api` namespace has **no** `POST`/`PATCH`/`DELETE` —
only `index`/`show` plus `players#stats`, `players#stats_export`, `round_players#meta`.

### Auth is session-cookie only

`app/models/user.rb:4` — `devise :database_authenticatable, :confirmable, :registerable,
:recoverable, :rememberable, :trackable, :validatable`. No `devise-jwt`, no `doorkeeper` in the
Gemfile. `:confirmable` matters: unconfirmed users cannot sign in. (`:rememberable` is a no-op for a
token client — remember-me is a cookie mechanism; harmless to leave. `:trackable` bumps
`last_sign_in_at` only on the sign-in dispatch, not per request — fine.)

`Api::ApplicationController#disable_http_cache` already sends `Cache-Control: no-store` on every API
response, so there is no server cache for the app to worry about; any offline/ETag caching is a
client-side concern and out of v1 scope.

### What has an API vs what does not

React pages (all under the `react_application` layout): `leagues#index`, `players#index`,
`players#leagues_list`, `players#show`, `results#index`, `round_players#index`, `leaderboard#index`
(added in #549). These are the API-backed screens. Note the manager profile (`users#show_manager`,
linked from the leaderboard) is server-rendered haml with no API.

Everything else in `app/views/` is haml with server-rendered forms — including the core weekly
actions: **`lineups`** (setting a squad), `auctions` / `auction_rounds` / bid submission,
`substitutes`, `transfers`, `tours`, `matches`, `joins`, user profile. **None of these have any
API.** They are out of scope for v1 and are the bulk of a future phase 2.

No server-side code consumes our own API (only external fotmob calls in
`app/services/tournament_rounds/fotmob_parser.rb` and friends).

### Response contract already in use

Collections (`Api::ApplicationController#response_options`):

```json
{ "data": [...], "meta": { "size": 120, "page": { "per_page": 25, "total_pages": 5, "current_page": 1 } } }
```

Errors (`Api::ApplicationController#not_found`):

```json
{ "errors": [{ "key": "not_found", "message": "Resource not found" }] }
```

### Client param encoding

`app/client/api/axios.ts` sets `baseURL = "/api"` and serialises params with
`qs.stringify(params, { arrayFormat: "brackets", encodeValuesOnly: true })`. Filters therefore
arrive as `filter[club_id][]=1&filter[position][]=Dc`, ordering as `order[field]`/`order[direction]`.

---

## Part A — Token authentication (Rails)

### A1. Install `devise-jwt`

Chosen over a hand-rolled token table so Devise stays the single source of truth for passwords.

Revocation strategy — pick **Denylist**:

- *JTIMatcher*: a `jti` column on `users`, no extra table, but signing out on one device kills
  tokens on all of them.
- *Denylist*: a `jwt_denylists (jti, exp)` table; revokes only the token used. Phone + tablet +
  web at once is a normal scenario, and JTIMatcher breaks it.

`config/initializers/devise.rb`:

```ruby
config.jwt do |jwt|
  jwt.secret = Rails.application.credentials.devise_jwt_secret_key
  jwt.dispatch_requests   = [['POST',   %r{^/api/v1/auth/sign_in$}]]
  jwt.revocation_requests = [['DELETE', %r{^/api/v1/auth/sign_out$}]]
  jwt.expiration_time = 30.days.to_i
end
```

Use a **dedicated** secret in credentials. Do not reuse `secret_key_base` — rotating one must not
invalidate the other.

**Token lifetime — sliding re-issue instead of a hard 30-day expiry.** A companion app is opened
weekly; a fixed 30-day token logs everyone out roughly monthly (see Risk 1). Full refresh tokens
are out of v1 scope, but a cheap middle ground avoids the forced logout without that machinery: on
any authenticated request, if the token is within ~7 days of `exp`, re-issue a fresh JWT in the
`Authorization` response header and have the Dio interceptor persist it. Revocation still works via
the Denylist. This is a few lines, not a refresh-token subsystem.

**Denylist grows and is not self-pruning.** `jwt_denylists (jti, exp)` accumulates a row per
revoked (or, with sliding re-issue, per superseded) token. `devise-jwt` never deletes expired rows.
Add an index on `jti` and a periodic cleanup (`DELETE FROM jwt_denylists WHERE exp < now()`), e.g. a
daily rake/cron task alongside the existing schedule in `config/schedule.rb`.

### A2. Auth endpoints

`Api::Auth::SessionsController` + `Api::MeController`:

| Method | Path | Behaviour |
|---|---|---|
| `POST` | `/api/v1/auth/sign_in` | `{email, password}` → 200 + user payload; JWT in the `Authorization` response header |
| `DELETE` | `/api/v1/auth/sign_out` | revokes the token (Denylist) |
| `GET` | `/api/v1/me` | current user, their teams, settings |

Handle `:confirmable` explicitly: an unconfirmed account must return 401 with a **distinct error
key**, so the app can say "confirm your email" rather than "wrong password".

**Make auth *failures* return JSON, not just the success path.** `Api::ApplicationController <
ActionController::Base`, so a failed `sign_in` (wrong password, unconfirmed) goes through Devise's
default Warden **failure app, which redirects to `/users/sign_in` (HTML)** — the client gets a 200
with an HTML body, exactly the debugging trap noted in A3. The "distinct error key" above is only
reachable once this returns JSON.

Do it with a **scoped custom `failure_app`** that emits `401 { errors: [...] }` only for JSON/API
requests and delegates to Devise's default for everything else. **Do not** reach for the one-line
`config.navigational_formats = []` — that flag is global and would make Devise answer *HTML* auth
failures with a bare 401 as well, breaking the existing web flow where a logged-out visitor to a
protected page is redirected to `/users/sign_in`. That regression hits current web managers, not
just the API — which is why the fix must be request-format-scoped, not a global toggle.

**CSRF applies to `sign_in` from day one.** `POST /api/v1/auth/sign_in` is itself a write on an
`ActionController::Base` subclass, so `protect_from_forgery` will reject it. Add
`protect_from_forgery with: :null_session` (or `skip_forgery_protection`) to the auth controller
now — this is not a "when write endpoints arrive" concern (A3.5); the auth POST *is* the first write
endpoint.

Registration and password reset: v1 deep-links to the website. Both flows already exist for web
with mailers and confirmation; duplicating them in the app is a lot of work for little gain.

### A3. Close the API — merge with the lockdown work

**This stage and the API lockdown are the same edit to the same controller. Do them together.**
Wiring JWT after closing the API means rebuilding the auth layer twice.

`devise-jwt` registers a warden strategy for the `user` scope, so `current_user` resolves from
either the session cookie (web SPA) or an `Authorization: Bearer` header (app). That means one
guard serves both clients.

Steps:

1. In `app/controllers/api/application_controller.rb`, replace `before_action :authenticate_user!`
   with a guard that renders JSON instead of redirecting. Devise's default redirects to
   `/users/sign_in`, which axios follows and receives HTML with status 200 — confusing to debug.

   ```ruby
   before_action :authenticate_api_user!

   def authenticate_api_user!
     return if user_signed_in?

     render json: { errors: [{ key: UNAUTHORIZED_KEY, message: UNAUTHORIZED_MSG }] },
            status: :unauthorized
   end
   ```

2. Remove `skip_before_action :authenticate_user!` from all 9 API controllers listed above.

3. Remove `skip_before_action :authenticate_user!, only: %i[index leagues_list]` from
   `app/controllers/players_controller.rb:2`.

   **Consequence, confirmed with the product owner on 2026-07-29: `/players` goes behind login.**
   Without this you get a broken half-state — the HTML renders for anonymous visitors while every
   `/api` call returns 401. Checked: no public view links to `/players`; the only links are in
   `app/views/layouts/_left_nav`, `_right_nav`, `_mob_header`, which already render for signed-in
   users only.

4. Leave public: `welcome`, `articles`, `links`, `subscriptions`, `weekly_teams#show`,
   `users#show_manager`. Plain haml, no `/api` calls.

   **Decide on the Leaderboard — it postdates this plan (#549) and is currently public.**
   `/leaderboard` is a React page backed by `api/leaderboard#index`, and the "Rankings" link renders
   for everyone (`_left_nav`, `_mob_header`). It is a browsing screen exactly like `/players`, so the
   **default is to close it the same way** — remove the `skip_before_action` on
   `api/leaderboard_controller.rb` and put the page behind login. Keep it public **only** on an
   explicit product call (e.g. an open, shareable/SEO rankings page). Either way, move the **page and
   its API together**: a public page whose `/api` call 401s (or vice versa) is the broken half-state
   from step 3.

5. CSRF: not an issue for today's read-only API (GETs are not checked). When write endpoints
   arrive, Bearer-authenticated requests must bypass it —
   `protect_from_forgery with: :null_session` in `Api::ApplicationController`.

**Known gap, accepted deliberately:** login stops anonymous scripts, not a registered scraper.
Signup is open, so anyone can create an account and pull the same data — and a token is *easier*
to automate than a cookie, so this gets more relevant once Part A ships. The real second layer is
per-user/IP rate limiting on `/api/*` (`rack-attack`) with a stricter cap on `stats_export`. Not
scoped here; raise it with the product owner separately.

### A4. Freeze the contract before the app ships

Once the app is in the stores, old versions live on phones for months and a serialiser change
breaks them. While there is still only one consumer:

- Move the API under **`/api/v1`** (routes + `app/client/api/axios.ts` `baseURL`). Cheap today,
  painful in a year. This is a **namespace move, not controller duplication** — one set of
  controllers stays; only the path (and `baseURL`) changes.

  **Cutover caveat — dual-route alias.** A hard move makes `/api/...` 404 immediately; a browser
  still holding the *old* SPA bundle keeps calling `/api` and breaks until the tab reloads. To make
  the switch seamless, route **both** `/api/v1` and `/api` to the same controllers for a release or
  two, then delete the `/api` alias. Keep it DRY — define the resources once and mount them under
  both scopes rather than copy-pasting the list:

  ```ruby
  api_routes = proc do
    resources :players, only: %i[index show] do
      get :stats, on: :member
      get :stats_export, on: :collection
    end
    resources :leagues, only: %i[index show] do
      resources :results, only: [:index]
      resources :teams, only: [:index]
    end
    # ... seasons, tournaments, round_players, leaderboard, etc.
  end

  scope '/api/v1', module: 'api', as: 'api_v1', &api_routes  # canonical
  scope '/api',    module: 'api', as: 'api',    &api_routes  # temporary alias — remove after cutover
  ```

  Controllers stay in `Api::` (`module: 'api'`), so nothing moves on disk. Drop the unversioned
  `/api` scope once old SPA sessions have cycled out — leaving it forever recreates the "implicit,
  unversioned path" the whole step exists to retire.
- Treat the `data`/`meta` shape above as a frozen contract.
- Add `rescue_from ActiveRecord::RecordNotFound` to `Api::ApplicationController` returning JSON 404.
  Today only the manual `not_found` exists, so some paths fall through to an HTML error page.
- **Complete the OpenAPI spec and make it the contract of record.** `swagger/v1/swagger.yaml` already
  exists (rswag, generated by `rake rswag:specs:swaggerize` from `spec/requests/api/*_spec.rb`) but
  covers only some endpoints — e.g. `api/leaderboard` was documented in #549, but the app-consumed
  players/leagues/results/round_players paths must all be covered before the app ships. This same
  spec is the input for the Dart client codegen in B2, so gaps here become hand-written drift there.

### A5. Specs

Request specs for: successful sign-in, wrong password, unconfirmed account, sign-out revoking the
token, Bearer access to an existing endpoint, and 401 JSON for an anonymous request.

Note the existing suite: all 10 files in `spec/requests/api/` currently make **zero** `sign_in`
calls, so closing the API turns them all red. Add `login_user` (already defined in
`spec/support/auth_helper.rb`) to each, and update the anonymous cases in
`spec/requests/players_spec.rb` to expect a redirect to sign-in.

---

## Part B — Flutter app v1

### B0. Why native (decision 2026-08-01)

Two cheaper paths were weighed and rejected:

- **WebView wrapper** — rejected: `viewport` meta exists only in `react_application.html.haml`, so
  the legacy `lineups`/auction pages render at 980px and scale down (details in B4). A wrapper would
  look worse than mobile Safari.
- **PWA over the existing React SPA** — the honest cheap option for a *read-only* v1: the SPA is
  already responsive, so a manifest + service worker gives an installable, offline-capable app with
  zero model duplication and no store overhead. Rejected in favour of native for: real push
  notifications (deadline/auction reminders — the actual retention hook), first-class store presence,
  and a foundation for the phase-2 write flows (lineups, bids) that a browsing PWA would not shorten.
  Accepted cost: a separate Dart codebase and models that must track the API (mitigated by codegen —
  B2).

### B1. Skeleton

Dart + Flutter. `dio` (HTTP), `flutter_secure_storage` (JWT in Keychain/Keystore), `go_router`
(navigation), `freezed` + `json_serializable` (models), `riverpod` (state). Two flavours: staging
and production.

### B2. API layer, mirroring `app/client/api`

- Dio interceptor attaches `Authorization: Bearer`; on 401 it clears the token and routes to login.
  It must also **read a refreshed `Authorization` header off responses and persist it** — that is the
  client half of the sliding re-issue in A1.
- **Generate the models and client from the OpenAPI spec, don't hand-write them.** With A4's
  `swagger/v1/swagger.yaml` complete, run `openapi-generator` (dart-dio target) so the Dart types
  track the Rails serialisers automatically; hand-written `freezed` models silently drift when a
  serialiser changes. The serialisers in `app/serializers/` (`Player`, `PlayerBase`, `PlayerStats`,
  `PlayerSeasonStat`, `League`, `LeagueBase`, `Result`, `Team`, `TeamSlim`, `Season`, `Tournament`,
  `Division`, `RoundPlayerStats`, `Club`, `LeaderboardEntry`) are the reference for what the spec must
  cover — not the thing to transcribe by hand.
- **Easy day to lose:** match the `qs` bracket encoding described above. Configure Dio with the
  equivalent of `ListFormat.brackets`, otherwise filters are silently ignored by
  `Api::PlayersController#filter_params`. (Codegen may not get this right on its own — verify.)

### B3. Screens — exactly the pages that already have an API

1. **Login**
2. **Players** — list with filters (tournament, club, position, league, price, score, minutes,
   teams count), sorting, pagination → `/api/v1/players`
3. **Player card** + per-season stats → `/api/v1/players/:id`, `/api/v1/players/:id/stats`
4. **Leagues** — list → `/api/v1/leagues`; table → `/api/v1/leagues/:id/results`;
   squads → `/api/v1/leagues/:id/teams`
5. **Team** → `/api/v1/teams/:id`
6. **Round** — player scores for a round, filters and deadline state →
   `/api/v1/tournament_rounds/:id/round_players` and `.../meta`
7. **Switchers** for season and tournament → `/api/v1/seasons`, `/api/v1/tournaments`
8. **Rankings** (managers leaderboard) — metric tabs (win rate / avg score / titles / matches),
   tournament filter → `/api/v1/leaderboard`. Added in #549; include it in v1 since the endpoint,
   pagination and filters already exist. Tapping a manager deep-links to the web profile
   (`users#show_manager` is server-rendered, no API — same deep-link pattern as registration in A2).

### B4. Explicitly out of scope for v1

Setting a lineup, auction bids, transfers, applying to a tournament. No endpoints exist for any of
it. Position v1 honestly, internally and in the store listing: **a companion app for browsing**,
not a replacement for the site. The manager's main weekly action stays in the browser until phase 2.

A note on why a WebView wrapper is not the shortcut it looks like: `viewport` meta exists **only**
in `app/views/layouts/react_application.html.haml:5`. The legacy `application` layout has none, so
those pages render at 980px and scale down — and the legacy pages are precisely `lineups` and the
auction. A wrapper would look worse than mobile Safari. (Separately tracked as the Viewport
Migration item in `docs/BACKLOG.md`.)

### B5. Release

Developer accounts (Apple $99/yr, Google $25 one-off), icons, screenshots, privacy policy. App
Store rejects thin website wrappers; a native v1 does not fall under that rule.

---

## Sequencing

- **A1 → A2 → A3** are blockers for everything else.
- **A3 must be done together with the API lockdown**, not after it.
- Part B can start in parallel once A2 is done — there is something to log in against.

## Risks

1. **Token lifetime.** A hard 30-day expiry logs weekly users out monthly. Full refresh tokens are
   out of v1 scope; the chosen mitigation is **sliding re-issue** (A1) — a token near `exp` is
   re-minted on the next request. Keeps the Denylist as the revocation mechanism.
2. **JWT secret rotation** instantly logs out every app user. Keep it separate from
   `secret_key_base`.
3. **Contract lock-in** after store release — the reason for `/api/v1` in A4.
4. **Open signup** limits what closing the API actually buys (see A3): with `:confirmable` a scraper
   must confirm an email, but that is a mild barrier. The sharpest target is
   `GET /api/players/stats_export` (a whole season as CSV). Recommend excluding it from the app scope
   entirely and, separately, rate-limiting it hard (`rack-attack`) or restricting it to moderators —
   the app never needs bulk CSV.

## Project conventions to follow

See `CLAUDE.md`. Most relevant here:

- Never run `git commit` or `git push` — the user does that.
- Run the full test suite **and** full RuboCop after each task; both must be green.
- i18n: edit `config/locales/{en,ua}.yml`, then `bundle exec i18n export` to regenerate
  `app/client/locales/locales.json` (generated — never hand-edit).