# Ruby & Rails Upgrade Plan

Plan for getting off an end-of-life Ruby and an almost-unsupported Rails. Audited 2026-10-04.

- **Rails 8.0.5 → 8.1.4 first, on its own.** 8.1.4 declares `ruby >= 3.2.0` and `rack >= 2.2.4`, so
  it needs neither the Ruby bump nor Rack 3. The two upgrades are independent; doing Rails first
  clears the nearest deadline with the smallest change.
- **Ruby 3.2.2 → 3.4.x, not 4.x.** 3.4 is supported to 2028-03-31, which is enough, and the stack
  carries gems six years old. 4.0 stays a later hop.
- **Scope**: versions and whatever breaks because of them. Opportunistic gem upgrades are listed
  last and are explicitly not part of the deadline work.

## Why now

| | ours | current | support |
|---|---|---|---|
| Ruby | 3.2.2 (2023-03) | 4.0.7 / 3.4.11 | **3.2 ended 2026-03-31** (final 3.2.11) |
| Rails | 8.0.5 | 8.1.4 | **8.0 security ends 2026-11-07** |
| Bundler | 2.4.21 | 2.7.x | — |

Ruby 3.2 already takes no security patches. Rails 8.0 stops taking them in a month. Note that 8.1's
own bug-fix window closes 2026-10-10 (security to 2027-10-10), so 8.2 will follow before long —
this is a hop, not a resting place.

## Current state (audit)

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
- The Ruby version is written in **four** places: `.ruby-version`, `Gemfile` (`ruby '3.2.2'`),
  `.github/workflows/ci.yml` (`ruby-version: 3.2.2`), `config/deploy.rb`
  (`set :rvm_ruby_version, 'ruby-3.2.2'`). `.ruby-gemset` is `fanta`.
- Production runs RVM + Passenger (`capistrano-rvm`, `capistrano-passenger`), so a Ruby bump is a
  server operation, not just a repo edit.

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
until bootstrap reaches 5.3 (Phase 6). Everything else is a 3.0 deadline. `quietDeps` hides the
vendor noise, exactly as the React build already does.

## Phases

**Phase 1 — Rails 8.0.5 → 8.1.4.** Independent of everything below; ship it first. `~> 8.0.0` →
`~> 8.1.0`, `bin/rails app:update`, review the generated diff rather than accepting it, work through
deprecations, then move `config.load_defaults` to 8.1 as a separate commit so a regression can be
bisected to the defaults rather than the version. Full suite + RuboCop at each step. ~1–2 days.

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

**Phase 4 — Flip the version.** All four pin sites in one commit, plus `.ruby-gemset` if the gemset
is renamed. CI is the gate: it must go green on 3.4 before anything reaches a server. Watch for the
3.4 behaviour changes that bite quietly — frozen-string-literal "chilled string" warnings and the
changed `Hash#inspect` format (the latter can break specs that compare inspected output). ~0.5 day.

**Phase 5 — Production rollout.** `rvm install ruby-3.4.x` on the server, recreate the `fanta`
gemset, rebuild Passenger against the new Ruby, then deploy with `rvm_ruby_version` updated. Keep
the old Ruby installed until the new one has served a full day, so a rollback is a Passenger restart
rather than a reinstall. Do it outside an auction window — the auction cron (`auction_rounds:process`,
every 2 min) and the live-score pass must not be mid-flight. ~0.5 day plus watching.

**Phase 6 — Opportunistic, after the deadline work.** `react_on_rails 13.4 → 17` (four majors; needs
`ruby >= 3.3`, so Phase 4 unblocks it, and it releases the `connection_pool` pin), `shakapacker
7.1 → 10`, `sprockets 3.7.2 → 4.4.1` (manifest already in place) which in turn frees Rack 3,
`puma 6 → 8`, `devise 4.9 → 5`, `bootstrap 4.3.1 → 5.3`, `chartkick 3.4 → 5`. Each on its own PR.
Drop `webdrivers` outright — the gem is deprecated in favour of Selenium Manager, which is built into
`selenium-webdriver`.

## Effort

Phase 1 ~1–2d and is the urgent one. Phases 2 and 4 ~0.5d each, Phase 3 ~0.5–1d, Phase 5 ~0.5d plus
observation. Total ~3–5 days to a supported Ruby and Rails, excluding Phase 6. The estimate no
longer carries an unknown: sassc was the one open question and it has been measured.

Ship as separate PRs — Rails, then Ruby — so that if something surfaces in production it is obvious
which of the two caused it.
