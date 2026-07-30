# Plan: Token Auth + Flutter App v1

> Self-contained handoff. Everything needed to start is in this file — no external context required.
> Written 2026-07-29 against branch `staging` @ `0c256dcd`.
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

`rack-cors` is not installed, so browsers block cross-origin JS reads — but server-side scraping
(`curl`, scripts) is unrestricted. `GET /api/players/stats_export` returns a whole season of player
stats as CSV, anonymously.

### The API is read-only

Routes live in `config/routes.rb:177`. The `api` namespace has **no** `POST`/`PATCH`/`DELETE` —
only `index`/`show` plus `players#stats`, `players#stats_export`, `round_players#meta`.

### Auth is session-cookie only

`app/models/user.rb:4` — `devise :database_authenticatable, :confirmable, :registerable,
:recoverable, :rememberable, :trackable, :validatable`. No `devise-jwt`, no `doorkeeper` in the
Gemfile. `:confirmable` matters: unconfirmed users cannot sign in.

### What has an API vs what does not

React pages (all under the `react_application` layout): `leagues#index`, `players#index`,
`players#leagues_list`, `players#show`, `results#index`, `round_players#index`. These are the
API-backed screens.

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

### A2. Auth endpoints

`Api::Auth::SessionsController` + `Api::MeController`:

| Method | Path | Behaviour |
|---|---|---|
| `POST` | `/api/v1/auth/sign_in` | `{email, password}` → 200 + user payload; JWT in the `Authorization` response header |
| `DELETE` | `/api/v1/auth/sign_out` | revokes the token (Denylist) |
| `GET` | `/api/v1/me` | current user, their teams, settings |

Handle `:confirmable` explicitly: an unconfirmed account must return 401 with a **distinct error
key**, so the app can say "confirm your email" rather than "wrong password".

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
  painful in a year.
- Treat the `data`/`meta` shape above as a frozen contract.
- Add `rescue_from ActiveRecord::RecordNotFound` to `Api::ApplicationController` returning JSON 404.
  Today only the manual `not_found` exists, so some paths fall through to an HTML error page.

### A5. Specs

Request specs for: successful sign-in, wrong password, unconfirmed account, sign-out revoking the
token, Bearer access to an existing endpoint, and 401 JSON for an anonymous request.

Note the existing suite: all 10 files in `spec/requests/api/` currently make **zero** `sign_in`
calls, so closing the API turns them all red. Add `login_user` (already defined in
`spec/support/auth_helper.rb`) to each, and update the anonymous cases in
`spec/requests/players_spec.rb` to expect a redirect to sign-in.

---

## Part B — Flutter app v1

### B1. Skeleton

Dart + Flutter. `dio` (HTTP), `flutter_secure_storage` (JWT in Keychain/Keystore), `go_router`
(navigation), `freezed` + `json_serializable` (models), `riverpod` (state). Two flavours: staging
and production.

### B2. API layer, mirroring `app/client/api`

- Dio interceptor attaches `Authorization: Bearer`; on 401 it clears the token and routes to login.
- Models from the existing serialisers in `app/serializers/`: `Player`, `PlayerBase`, `PlayerStats`,
  `PlayerSeasonStat`, `League`, `LeagueBase`, `Result`, `Team`, `TeamSlim`, `Season`, `Tournament`,
  `Division`, `RoundPlayerStats`, `Club`.
- **Easy day to lose:** match the `qs` bracket encoding described above. Configure Dio with the
  equivalent of `ListFormat.brackets`, otherwise filters are silently ignored by
  `Api::PlayersController#filter_params`.

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

1. **Token lifetime.** 30 days means users get logged out monthly. Refresh tokens are not in v1
   scope — they are a meaningful chunk of work. Alternative: a longer expiry with the Denylist as
   the revocation mechanism.
2. **JWT secret rotation** instantly logs out every app user. Keep it separate from
   `secret_key_base`.
3. **Contract lock-in** after store release — the reason for `/api/v1` in A4.
4. **Open signup** limits what closing the API actually buys (see A3).

## Project conventions to follow

See `CLAUDE.md`. Most relevant here:

- Never run `git commit` or `git push` — the user does that.
- Run the full test suite **and** full RuboCop after each task; both must be green.
- i18n: edit `config/locales/{en,ua}.yml`, then `bundle exec i18n export` to regenerate
  `app/client/locales/locales.json` (generated — never hand-edit).