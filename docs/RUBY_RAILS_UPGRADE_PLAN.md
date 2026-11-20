# Platform Upgrade Plan

Plan for getting off an end-of-life Ruby, an almost-unsupported Rails, an end-of-life Node and —
behind them — an Ubuntu that runs out of support in 2027. First audited 2026-10-04, re-audited and
widened to the server on 2026-11-01.

- **Rails 8.0.5 → 8.1.4 first, on its own, and now.** Security for the 8.0 series ends
  **2026-11-07**. 8.1.4 declares `ruby >= 3.2.0` and `rack >= 2.2.4`, so it needs neither the Ruby
  bump nor Rack 3. Repo-only: nothing to do on the server.
- **Ruby 3.2.2 → 3.4.x, not 4.x.** 3.4 is in normal maintenance, which is enough, and the stack
  carries gems six years old. 4.0 stays a later hop.
- **Node 20.10.0 → 24.** 20 died 2026-04-30. CI is already pinned to 24; the server is not.
- **Ubuntu 22.04 → 24.04 last, and by replacing the instance, not upgrading it in place.**
- **Scope**: versions and whatever breaks because of them. Opportunistic gem upgrades are listed
  last and are explicitly not part of the deadline work.

## Why now

| | ours | current | support |
|---|---|---|---|
| Rails | 8.0.5 | 8.1.4 | **8.0 security ends 2026-11-07** |
| Ruby | 3.2.2 (2023-03) | 4.0.x / 3.4.x | **3.2 ended 2026-04-01** (final 3.2.11) |
| Node | 20.10.0 (2024-01) | 24 LTS / 26 LTS | **20 ended 2026-04-30** |
| Ubuntu | 22.04.3 | 24.04 / 26.04 | 22.04 standard ends 2027-04 |
| Bundler | 2.4.21 | 2.7.x | — |

Three of the five are already past end of life and take no security patches. Rails joins them in a
week. Ubuntu is the only one with real runway, which is why it goes last even though it disturbs
the most.

Rails 8.1's own bug-fix window closed 2026-10-10 (security to 2027-10-10), so 8.2 will follow
before long — this is a hop, not a resting place.

## Order, and why

```
1. Rails 8.1      repo only          deadline in 6 days
2. Ruby 3.4       repo + server      already EOL
3. Node 24        server mostly      already EOL
4. Ubuntu 24.04   new instance       deadline 2027-04
```

The OS goes last despite redoing part of steps 2 and 3. A release upgrade replaces glibc and
OpenSSL, so every RVM Ruby, every native gem and Passenger have to be rebuilt against the new
system afterwards — which is most of the server side of the Ruby step, done twice.

That duplication is accepted on purpose: it is about an hour of rebuild, against three components
that are taking no security patches *today* and an OS that is covered until 2027-04. Paying an hour
to fix the live exposure sooner is the right trade. If the OS move slips into 2027 the order should
be revisited, because by then the waste and the risk swap places.

## Current state (audit)

### Repo

- 124 outdated gems. The oldest pins: `sprockets = 3.7.2` (2015 line), `sassc-rails 2.1.2`
  (released 2019-06-18), `sassc 2.4.0` (2020-06-02), `react_on_rails = 13.4` (current 17.x),
  `shakapacker = 7.1` (current 10.3), `bootstrap 4.3.1`, `chartkick 3.4.0`.
- **Rack is held at 2.2.23 by exactly one gem**: `sprockets 3.7.2` requires `rack > 1, < 3`. Nothing
  else in the tree wants Rack 2, and Rails 8.1 does not want Rack 3 — so this is not on the critical
  path.
- `app/assets/config/manifest.js` already exists, so sprockets 3 → 4 is mostly configuration rather
  than a migration, whenever it is picked up.
- `connection_pool` is pinned `~> 2.4` solely because `react_on_rails 13.4.0` breaks on 3.x (the
  comment in the Gemfile says so). Upgrading react_on_rails releases it.
- The Ruby version is written in **five** places, not four as the first audit said:
  `.ruby-version`, `Gemfile` (`ruby '3.2.2'`), `.github/workflows/ci.yml`,
  `config/deploy.rb:44` and — easy to miss — **`Capfile:18`**, which sets `rvm_ruby_version` a
  second time. Miss the Capfile and Capistrano deploys against the old Ruby while every other
  file says otherwise. Also mentioned, but not load-bearing: `README.md:22` and the commented
  Passenger paths in `config/deploy/nginx.conf.example`. `Gemfile.lock` carries it too and is
  regenerated. `.ruby-gemset` is `fanta`.
- **The VCR cassettes are not a problem.** They record `ruby/3.2.2p53` inside the stored
  User-Agent, but `spec/rails_helper.rb:36` sets no `match_requests_on`, so VCR falls back to its
  default of method + URI. Headers are not compared and a Ruby bump will not invalidate them.

### Server

Ubuntu 22.04.3, EC2 `t3.xlarge`, 15 GB RAM, nginx 1.18.0 + Passenger 6.0.18, RVM, OpenSSL 3.0.2.
Postgres is RDS 18.3 and lives outside the box.

- **Disk is the binding constraint, and the only one: 13 G used of 16 G, 3.1 G free.** Largest
  consumers: `/usr` 4.3 G (RVM alone 766 M, holding an unused `ruby-3.0.1` beside `ruby-3.2.2`),
  `/var` 5.2 G (`shared/bundle` 840 M, `shared/log` 186 M, 5 kept releases 314 M), a 2.1 G
  swapfile.
- Nothing else is short. RAM: 2.5 G of 15.8 G in use, swap untouched across 19 days of uptime,
  Passenger capped at a pool of 6 (currently 5 processes of ~105 M), so the application tops out
  near 630 M. CPU: 15–20% sustained, 15-minute load 1.54 on four cores, no steal, request queue
  empty. Sized on 2026-11-01. Read this before buying a bigger machine — see Phase 8.
- **Node was installed by hand**: `/usr/local/bin/node`, a 96 MB official binary dated 2024-01-06.
  Not apt, not nvm, no `.nvmrc` and no `engines` field in `package.json` — nothing in the repo
  records which Node the server is supposed to run. `yarn` is classic 1.22.21, installed the same
  way. Note that apt also has `nodejs 12.22.9` installed from the Ubuntu archive; it is shadowed by
  `/usr/local/bin` today, and a PATH change during an OS upgrade would silently expose it.
- Deploy builds assets on the server: `Capfile` loads `capistrano/rails` (precompile) and
  `capistrano/yarn` (`yarn install`), so the server's Node is what produces the production bundle.
  CI's Node only ever has to install dependencies and run the suite.
- The real state on the box is small: `shared/public` is 125 M (uploads and system) and
  `shared/config`, 12 K. Everything else under `shared/` is rebuildable. This is what makes
  replacing the instance cheap.

## sassc: measured, and smaller than it looks

`sassc-rails` has not shipped since 2019 and `sassc` since 2020; both wrap libsass, which the Sass
team deprecated. It is a C++ native extension, so it was the obvious candidate to refuse to build on
3.4. Audited 2026-10-04 — the conclusion is that it can simply be replaced, whatever 3.4 does to it.

**Where it is used.** One entry point: `app/assets/stylesheets/application.scss`, served to both
layouts by `stylesheet_link_tag 'application'`. A flat graph — 30 local partials imported one level
deep, plus `bootstrap` (gem 4.3.1), `flag-icon` (gem) and the local `bootstrap-toggle`. 33 files,
18 478 lines. Separately `app/assets/stylesheets/rails_admin/`. No `.sass` indented-syntax files, so
there is no syntax migration.

**Where it is not.** The React side — 66 `.scss` files — already compiles through webpack's
`sass-loader` on the npm `sass` package (dart-sass 1.99), configured for the modern API with
`quietDeps` in `config/webpack/commonWebpackConfig.js`. Half the stylesheets left libsass long ago.

**It already compiles under dart-sass.** Building the real `application.scss` with dart-sass 1.99,
with the actual gem load paths for bootstrap and flag-icon, produces 675 KB of CSS and exits 0. Our
own code contributes exactly three deprecated constructs, all in one function in
`responsive_helpers.scss` (lines 20–22): `type-of` → `meta.type-of`, `unitless` →
`math.is-unitless`, and `/` → `math.div`.

**Replacement: `dartsass-sprockets`.** It keeps the Sprockets integration, the `stylesheet_link_tag`
and — the part that matters — the gem asset paths that make `@import "bootstrap"` resolve at all.
One line in the Gemfile. `dartsass-rails` compiles outside Sprockets into `app/assets/builds` and
would need those gem paths wired by hand; `cssbundling-rails` would reuse the npm `sass` we already
have (one Sass implementation for the whole app, the cleanest end state) at the cost of a build step
in development and deploy. Note that nothing depends on sassc's CSS compressor —
`config.assets.css_compressor = :sass` is commented out in both `production.rb` and `staging.rb`.

**The constraint to carry forward.** With vendor warnings unsilenced the build prints 371
deprecations, nearly all from bootstrap 4.3.1: 122 `@import`, 94 color-functions, 80 global-builtin,
**65 `slash-div`**. Slash division is removed in **Dart Sass 2.0**, so dart-sass must stay `< 2.0`
until bootstrap reaches 5.3 (Phase 9). Everything else is a 3.0 deadline. `quietDeps` hides the
vendor noise, exactly as the React build already does.

## Phases

**Phase 1 — Rails 8.0.5 → 8.1.4.** Independent of everything below; ship it first, the deadline is
2026-11-07. `~> 8.0.0` → `~> 8.1.0`, `bin/rails app:update`, review the generated diff rather than
accepting it, work through deprecations, then move `config.load_defaults` to 8.1 as a separate
commit so a regression can be bisected to the defaults rather than the version. Full suite +
RuboCop at each step. ~1–2 days.

**Phase 2 — Ruby 3.4 dry run.** Scratch gemset, `bundle install`, run the suite. No pins changed, no
commits. Produces the list of gems that actually need attention — in particular whether sassc builds.
Also check the stdlib gems that left the default set in 3.4 (`csv`, `base64`, `mutex_m`, `observer`,
`abbrev`): `base64` is pinned `= 0.1.1` here and should simply be unpinned (0.3.0 is current).
~0.5 day.

**Phase 3 — Fix what the dry run found.** Sized by Phase 2, and smaller than first thought now that
sassc is measured: if it fails to build, swap `sassc-rails` for `dartsass-sprockets` and fix the
three deprecated calls in `responsive_helpers.scss`, then a visual pass over the pages. ~0.5–1 day.
Worth doing on its own merits even if sassc survives 3.4 — the gem has been unmaintained for six
years. The `@import` → `@use` migration is a separate, later errand (Dart Sass 3 deadline).

**Phase 4 — Flip the Ruby version.** All five pin sites in one commit — `.ruby-version`, `Gemfile`,
`.github/workflows/ci.yml`, `config/deploy.rb` **and `Capfile`** — plus `README.md` and
`.ruby-gemset` if the gemset is renamed. CI is the gate: it must go green on 3.4 before anything
reaches a server. Watch for the 3.4 behaviour changes that bite quietly — frozen-string-literal
"chilled string" warnings and the changed `Hash#inspect` format (the latter can break specs that
compare inspected output). ~0.5 day.

**Phase 5 — Ruby on the server.** `rvm install ruby-3.4.x`, recreate the `fanta` gemset, rebuild
Passenger against the new Ruby, then deploy with `rvm_ruby_version` updated. Free disk first (see
Phase 7) — RVM needs roughly a gigabyte to unpack, compile and populate a gemset, and there is only
3.1 G spare. Removing the unused `ruby-3.0.1` is the obvious place to take it from. Keep the old
Ruby installed until the new one has served a full day, so a rollback is a Passenger restart rather
than a reinstall. Do it outside an auction window — the auction cron (`auction_rounds:process`,
every 2 min) and the live-score pass (`tours:live_inject`, every 12 min) must not be mid-flight.
~0.5 day plus watching.

**Phase 6 — Node 20 → 24.** CI is already pinned to 24 (`.github/workflows/ci.yml`); the server is
the part that is left, and until it moves, CI builds the bundle on one Node and production builds
it on another. On the server this is a tarball swap into `/usr/local`, the same way the current one
got there — keep the old directory until a deploy has gone through, since a bad Node shows up as a
failed `yarn install` or a broken precompile, both mid-deploy. Three things worth doing at the same
time, because nothing currently records the intended version: add `engines.node` to `package.json`,
add a `.nvmrc`, and purge the apt `nodejs 12.22.9` so a PATH change can never expose it. Verify with
a real deploy, not just `node -v`: the risk is in webpack and the loaders, not the runtime.
~0.5 day. **Not yet verified:** nobody has run `yarn install` against Node 24 on this dependency
set — CI will be the first to try, and it has not run since being pinned.

**Phase 7 — Disk, before Ubuntu.** 3.1 G free is not enough for an OS move and is uncomfortably
close for Phase 5. The cheapest fix by far is to grow the EBS volume to **40–60 G** — an online
operation (`modify-volume`, then `resize2fs`) that needs no downtime, and a 16 G root under a
`t3.xlarge` is undersized anyway. Pick the same size for the Phase 8 replacement, so the new box
starts with the headroom this one never had.

Failing that, reclaimable without consequence: the unused `ruby-3.0.1` under RVM, `apt-get clean`,
`shared/log` (186 M, and logrotate is already configured), and trimming `keep_releases`. The 2.1 G
swapfile can go too — it has not been touched once in 19 days of uptime (`SwapFree == SwapTotal`),
because the box uses 2.5 G of its 15.8 G. Leave it in place during an *in-place* upgrade if one is
ever attempted, but it does not need recreating on a new machine.

**Phase 8 — Ubuntu 22.04 → 24.04, by replacing the instance.** Build a fresh 24.04 box, install
RVM + the target Ruby + Node + nginx/Passenger, deploy to it, copy `shared/public` (125 M) and
`shared/config`, then move the Elastic IP across. The database is RDS and is not involved.

**Size it the same — `t3.xlarge`, 4 vCPU, 16 G RAM — with a 40–60 G root instead of 16 G.** Only
the disk is short. Measured on 2026-11-01: 2.5 G of 15.8 G RAM in use, swap untouched across 19
days of uptime, and Passenger capped at a pool of 6 processes of roughly 105 M, so the application
cannot exceed about 630 M however busy it gets. CPU sits at 15–20% with a 15-minute load average
of 1.54 on four cores and no steal. Memory is over-provisioned roughly sixfold.

That makes 4 vCPU / 8 G — `c7i.xlarge`, say — the honestly right-sized shape, and it would cost
less. Resist it *here*: this phase already changes the OS, and Ruby and Node land around it, so
adding the instance type as a fourth variable means anything odd afterwards has four candidate
causes. Keep the machine identical, move the OS, then right-size later as its own change with
measurements from the new box. Do not cut the cores in either case — deploys run `yarn install`
and `assets:precompile` on the server, and webpack will take whatever CPU and memory it is given.

This is recommended over `do-release-upgrade` for three reasons: a 16 G root with 3.1 G free is a
bad place to attempt an in-place release upgrade, since running out of space halfway leaves a
system that is neither version; rollback becomes moving an IP back rather than restoring a
snapshot; and the new box can be smoke-tested at leisure while the old one keeps serving. What
makes it cheap is that the box holds almost no state — 125 M of uploads, and everything else is
either in RDS or rebuilt by a deploy.

Things that must be rebuilt rather than copied, because 24.04 moves glibc and OpenSSL (3.0.2 →
3.0.13): every RVM Ruby, every native gem (`pg`, `nokogiri`, and `sassc` if it is still around),
and Passenger. Note also that nginx jumps 1.18 → 1.24 and the Passenger module must be built
against the new nginx. Afterwards, re-point CI at the new image: `runs-on: ubuntu-24.04` in
`.github/workflows/ci.yml`, which is deliberately pinned to `ubuntu-22.04` today precisely so that
it matches this server. ~1 day plus a cutover window.

26.04 is skipped on purpose: Ubuntu does not offer a direct 22.04 → 26.04 path, and 24.04 is
supported to 2029-04, which is past the point where this plan will have been run again.

**Phase 9 — Opportunistic, after the deadline work.** `react_on_rails 13.4 → 17` (four majors; needs
`ruby >= 3.3`, so Phase 4 unblocks it, and it releases the `connection_pool` pin), `shakapacker
7.1 → 10`, `sprockets 3.7.2 → 4.4.1` (manifest already in place) which in turn frees Rack 3,
`puma 6 → 8`, `devise 4.9 → 5`, `bootstrap 4.3.1 → 5.3`, `chartkick 3.4 → 5`, yarn classic → berry.
Each on its own PR. Drop `webdrivers` outright — the gem is deprecated in favour of Selenium
Manager, which is built into `selenium-webdriver`.

## Effort

| phase | | effort |
|---|---|---|
| 1 | Rails 8.1 | ~1–2 d — **urgent, deadline 2026-11-07** |
| 2 | Ruby 3.4 dry run | ~0.5 d |
| 3 | Fix what it found | ~0.5–1 d |
| 4 | Flip the five pins | ~0.5 d |
| 5 | Ruby on the server | ~0.5 d + watching |
| 6 | Node 24 on the server | ~0.5 d |
| 7 | Disk | ~1 h (grow the volume to 40–60 G) |
| 8 | Ubuntu 24.04 cutover (same `t3.xlarge`, bigger root) | ~1 d + a window |
| 9 | Gem catch-up | open-ended, separate |

~3–5 days to a supported Ruby and Rails, another ~2 to a supported Node and OS, excluding Phase 9.
The Ruby estimate no longer carries an unknown: sassc was the one open question and it has been
measured. The OS estimate does carry one — nothing on a 24.04 box has been built yet.

Ship as separate PRs — Rails, then Ruby, then Node — so that if something surfaces in production it
is obvious which of them caused it. The OS move is not a PR at all; it is an infrastructure change
with its own rollback.
