---
name: mantra-team-pick-ua
description: "Ukrainian Premier League version of mantra-team-pick. Given a Mantra fantasy team URL or ID for a UPL league (mantrafootball.org), build optimal starting XI and 9-player bench (1 GK + 8 outfield) for the next round. There is no published 'probable lineups' source for the UPL, so predicted starters are inferred from each club's actual lineups in their last 3 matches, cross-referenced with the official UPL suspensions tracker and ad-hoc injury news. Examples: '/mantra-team-pick-ua https://mantrafootball.org/api/teams/123.json', '/mantra-team-pick-ua 123', '/mantra-team-pick-ua 123 lookback=5'"
---

# Mantra Team Pick — Ukraine (UPL)

Build a starting XI + bench for the next round of a Mantra fantasy football team competing in the **Ukrainian Premier League**. Same data flow as `mantra-team-pick` and `mantra-team-pick-it`, but the predicted XI is **inferred from recent-match lineups** instead of read from a probable-lineups site (none exists for the UPL).

## Inputs

Accept any of:
- Full URL: `https://mantrafootball.org/api/teams/123.json`
- HTML URL: `https://mantrafootball.org/teams/123`
- Bare ID: `123`
- Optional `lookback=N` — number of recent matches to use as the basis for predicted XI (default `3`, max `5`).
- Optional `submit=1` — after computing the lineup, push it to Mantra via the authenticated form endpoint (see Step 9). Default is recommend-only.

Extract team id and use `https://mantrafootball.org/api/teams/{id}.json`.

## Procedure

### Step 1 — Fetch team & roster

1. `GET https://mantrafootball.org/api/teams/{id}.json` → returns `players: [ids]`, `league_id`.
2. `GET https://mantrafootball.org/api/leagues/{league_id}.json` → returns `min_avg_def_score`, `max_avg_def_score`, `round`, `mantra_format`, `tournament_id`.
3. `GET https://mantrafootball.org/api/players.json?filter[team_id][]={id}&filter[league_id]={league_id}&page[size]=50` → returns full roster with `position_ital_arr`, `club`, `average_total_score`, `appearances`, `appearances_max`.

**Sanity check:** verify `tournament_id == 15` (Ukraine). If `1` (Serie A) — suggest `/mantra-team-pick-it`; if `2` (PL) — suggest `/mantra-team-pick`. Other ids — flag and proceed best-effort.

If the count of returned players differs from `players.length`, fetch missing ones individually via `/api/players/{player_id}.json`.

### Step 2 — Identify the next round and fixtures

`current_round = league.round`. Next round = `current_round + 1`.

For each unique `club` in the roster, find the next-round opponent and home/away. Best sources (try in order):
1. `https://upl.ua/ua` — official UPL site, current matchday calendar.
2. WebSearch query: `тур {next_round} УПЛ календар` → expect ua-football.com / sport.ua / football24.ua to surface the round table.
3. `https://football24.ua/tournament/ukrayina-50819` — round calendar with `Календар матчів (Тур N)`.

Build `{club → next_opponent, H/A}`. If a club's fixture can't be confirmed, state which.

### Step 3 — Derive predicted XI from recent matches

For each unique `club` in the roster, gather the **starting XI of the last `lookback` matches** (default 3). Sources, in order of preference:

1. **`ua-football.com`** — pre-match articles `*-startovi-skladi-*` are plain-text and include the full XI ("Сапутін - Малиш, Джордан, Яніч... " format). Search via WebSearch: `"{club_name}" стартові склади УПЛ тур` and pick the most recent N hits matching the club's recent rounds.
2. **`football24.ua/match/{slug}-{id}`** — match pages with "Основний склад" section listing 11 players + positions. URL pattern: lowercase team names hyphen-joined, then numeric id.
3. **`upl.ua/ua/report/view/{id}`** — official match reports; lineups shown as visual cards (harder to parse — fallback only).
4. **`tribuna.com/uk/football/tournament/upl/calendar/`** — calendar with linked match pages (often blocked from server-side fetch — try last).

For each roster player, compute **starts in last N**:
- `N/N` → **STARTING** (regular)
- `1..N-1` of N → **ROTATION (X/N starts)**
- `0/N` and player has season `appearances ≥ 16` → **ROTATION-FRINGE** (recent dropout — likely tactical or hidden injury)
- `0/N` and player has season `appearances < 16` → **DEEP BENCH**

Note: a player who started 0/3 but only because they were injured will be re-tagged in Step 4. Don't mark anyone OUT here based purely on missed starts.

If a roster player is missing entirely from the last `lookback` matches AND the season `appearances` doesn't match this gap (e.g., `appearances=20` but didn't play last 3), flag a "recent absence — investigate" note for Step 4.

### Step 4 — Cross-reference suspensions and injuries

**Suspensions (card-based):**

`GET https://upl.ua/ua/people/suspensions`. The official tracker lists, per player: name, club, "X match(es)" remaining. Parse and build `{player → matches_remaining}`. Anyone with `matches_remaining ≥ 1` for the next round is **OUT — disqualified**.

**Injuries (no central tracker exists for the UPL):**

For each club with at least one roster player whose status is uncertain (ROTATION-FRINGE, DEEP BENCH after recent absence, or any player flagged "recent absence" in Step 3), run a targeted WebSearch:

- `"{club_name}" травми перед матчем УПЛ {next_round}`
- `"{club_name}" кадрові втрати анонс УПЛ`

Expected sources: `ua-football.com` ("Шаран зіштовхнувся із кадровими втратами…"), `football24.ua` ("анонс і прогноз матчів УПЛ"), `sport.ua` (e.g. "В дербі з Карпатами Руху не допоможуть три гравці"). These articles list "У медичному штабі" / "Травмовані" / "Не зіграє" by name. Cross-check each name against the roster and tag:

- **OUT — травма** if the article confirms injury for the next round.
- **DOUBTFUL** if the article uses "під питанням" / "розчарував на тренуванні" / "очікується повернення".
- **CONFIRMED RETURN** if "повертається в склад" — bump back to STARTING/ROTATION based on Step 3 evidence.

If no article is found for a club, leave Step 3 tagging as-is and add an "unverified for {club}" note in the output.

Watch for translit/transliteration discrepancies — Mantra often stores names in Latin (`Sudakov`), but UPL articles are Ukrainian (`Судаков`). Match by club + jersey number where ambiguous; the API exposes `shirt_number` for each player.

### Step 5 — Pick the best module

Mantra modules and slot composition (same `config/mantra/team_modules.yml` as PL/Serie A):

| Module | Slots (1–11) |
|---|---|
| 3-4-3 | Por, Dc, Dc, Dc, E, E, M/C, C, W/A, W/A, A/Pc |
| 3-4-1-2 | Por, Dc, Dc, Dc, E, E, M/C, C, T, A/Pc, A/Pc |
| 3-4-2-1 | Por, Dc, Dc, Dc, E, M, M/C, E/W, T, T/A, A/Pc |
| 3-5-2 | Por, Dc, Dc, Dc, E, M, M/C, C, E/W, A/Pc, A/Pc |
| 3-5-1-1 | Por, Dc, Dc, Dc, M, M, C, E/W, E/W, T/A, A/Pc |
| 4-3-3 | Por, Dd, Dc, Dc, Ds, M, M/C, C, W/A, W/A, A/Pc |
| 4-3-1-2 | Por, Dd, Dc, Dc, Ds, M, M/C, C, T, A/Pc, A/Pc |
| 4-4-2 | Por, Dd, Dc, Dc, Ds, E, M/C, C, E/W, A/Pc, A/Pc |
| 4-1-4-1 | Por, Dd, Dc, Dc, Ds, M, C/T, C/T, W, W, A/Pc |
| 4-4-1-1 | Por, Dd, Dc, Dc, Ds, M, C, E/W, E/W, T/A, A/Pc |
| 4-2-3-1 | Por, Dd, Dc, Dc, Ds, M, M/C, T, T/W, W/A, A/Pc |
| 4-3-2-1 | Por, Dd, Dc, Dc, Ds, M, M/C, C, T/A, T/A, A/Pc |

**Note for UPL:** Ukrainian top-flight clubs lean toward 4-back schemes (4-2-3-1, 4-3-3, 4-3-2-1 dominate); 3-back is rarer than in Serie A. The algorithm is the same — pick the module that fits the most STARTING players.

Algorithm:
1. For each module, attempt to fill all 11 slots **using only STARTING players** from the roster. Slot fits if any of the player's `position_ital_arr` matches the slot's allowed positions (slash means OR).
2. Pick the module with the **most starters fitting** (ideally 11). On tie, prefer higher modificatore difesa.
3. If no module reaches 11 starters, document which slots required ROTATION fill-ins. Never use OUT players in the XI.

### Step 6 — Build the bench (9 players: 1 Por + 8 outfield)

Bench = exactly 1 goalkeeper + 8 outfield (squad total = 11 + 9 = 20).

From non-starting roster players, exclude all marked **OUT**. Rank remaining by:
1. **Position coverage** — at minimum: 1 Por, ≥2 Dc backups, ≥1 M/C backup, ≥1 W/E backup, ≥1 Pc/A backup.
2. **Likelihood** — STARTING > ROTATION (high N/lookback) > DOUBTFUL > ROTATION-FRINGE > DEEP BENCH.
3. **Matchup quality** — using the next-match map from Step 2:
    - **easy** — opponent is in UPL bottom-quartile (typical: Чорноморець, Полтава, Епіцентр, Кудрівка, Маріуполь — verify against current standings on `https://upl.ua/ua` or league JSON before tagging), OR an opponent missing 5+ first-team players.
    - **mid** — neutral.
    - **hard** — top-4 opponent (typical: Шахтар, Динамо, Полісся, Кривбас) or away to a top-4.
    - For attackers (W/A/Pc/T): easy = weak defense; hard = strong defense.
    - For defensive players (Dc/Dd/Ds/E/Por): easy = weak attack; hard = strong attack.
4. **Upside** — within same likelihood + matchup tier, prefer higher `average_total_score`.

If a critical role can't be filled, state the structural gap. Fill remaining bench slots by `likelihood × matchup_factor × avg` (matchup_factor ≈ 1.15 / 1.0 / 0.85 for easy / mid / hard).

### Step 7 — Modificatore difesa check

For 4-back modules: avg of 4 starting defenders (Dd + 2 Dc + Ds).
For 3-back modules: avg of 3 Dc + 1 best E.
Compare to `min_avg_def_score` / `max_avg_def_score` from the league JSON. State whether it falls in the corridor (✅) or out (❌, by how much).

### Step 8 — Output

Print a single Markdown table with **all 20 slots**, columns:

| Slot | Role | Player | Club | avg | apps | Last N | Status | Matchup |

- `Last N` column: e.g. `3/3` (started all of last 3) or `1/3` (1 of last 3 starts).
- `Status` uses UPL-aware tags: `регулярний` / `ротація` / `під питанням` / `OUT — травма` / `OUT — дискваліфікація (X матчів)`.
- `Matchup` column: `OPP (H/A) [easy/mid/hard]` — e.g. `Чорноморець (H) easy`, `Шахтар (A) hard`. Use Ukrainian club abbreviations.

Below the table, print:
- Module name + modificatore difesa value + corridor check + XI avg.
- Excluded from squad: X (OUT — травма), Y (OUT — дискваліфікація), Z (low apps), …
- Structural gaps (e.g. "No Pc backup available").
- **Fixture concentration warning** — if 3+ roster players appear in the same single UPL fixture, call it variance risk.
- **Unverified clubs** — list any club where injury news couldn't be located in Step 4.
- Substitution priority map: which bench player covers which starter on NG.

Keep total response under ~90 lines. No "Step 1…" headers in the final output — pure result.

### Step 9 — Optional: submit the lineup to Mantra

This step runs **only if the user passed `submit=1`**. Otherwise stop after Step 8.

Mantra has no public write API, but the authenticated form at `/teams/{team_id}/lineups/{lineup_id}/edit?team_module_id={mod_id}` accepts a standard Rails PATCH submission. The skill ships with `submit_lineup.py` (in this skill's directory) that handles auth, CSRF, slot discovery, and POST.

**Auth (precedence order — first one available wins):**

1. `MANTRA_COOKIE` env var — full Cookie header (`remember_user_token=…; _fanta_session=…`) copied from browser DevTools. Skips login entirely. Best when the user is debugging or the credentials file isn't available.
2. `MANTRA_EMAIL` + `MANTRA_PASSWORD` env vars — script does a Devise login flow (`GET /users/sign_in` → scrape CSRF → POST credentials with `remember_me=1`).
3. **Credentials file** — preferred for routine use. Default locations checked in order: `$MANTRA_CREDENTIALS` (if set) → `~/.config/mantra/credentials` → `~/.mantra-credentials`. Format is plain `KEY=VALUE` per line, `#` comments allowed:
   ```
   email=you@example.com
   password=your-password
   ```
   File mode must be `0600` (`chmod 600 ~/.config/mantra/credentials`); the script warns if it's wider but doesn't refuse. The script reads the file at runtime, never copies the password into argv, env-of-children, or logs.

The script never persists obtained cookies to disk — they live in memory for the duration of the run only.

**Module ID mapping** (server-side IDs, parsed from the edit page when in doubt):

| Module | id | Module | id | Module | id |
|---|---|---|---|---|---|
| 3-4-3 | 1 | 3-5-1-1 | 5 | 4-1-4-1 | 9 |
| 3-4-1-2 | 2 | 4-3-3 | 6 | 4-4-1-1 | 10 |
| 3-4-2-1 | 3 | 4-3-1-2 | 7 | 4-2-3-1 | 11 |
| 3-5-2 | 4 | 4-4-2 | 8 | 4-3-2-1 | 12 |

**Submit flow:**

1. Verify auth is available (cookie env var, email+password env vars, or credentials file at one of the default paths). If none — surface the same precedence-order help to the user with the credentials-file template as the recommended option.
2. Build the XI list as 11 round_player_ids in the order required by the chosen module (slots 0–10 — match the position composition table). Build the bench list as 9 round_player_ids (slots 11–19). The bench order matters only for tie-breaking on auto-substitution; sort by descending priority (best bench player first).
3. Run a **dry-run first** to validate auth, parse the edit page, and confirm the payload assembles cleanly:
   ```bash
   python3 ~/.claude/skills/mantra-team-pick-ua/submit_lineup.py \
     --team-id <team_id> \
     --module <e.g. 3-5-1-1> \
     --xi <11 comma-separated round_player_ids> \
     --bench <9 comma-separated round_player_ids>
   ```
   The script logs in (env vars or credentials file), auto-discovers the current lineup_id, parses the edit page, and prints the payload preview without POSTing. Default mode is dry-run.
4. **If the dry-run is clean** (auth ok, lineup_id discovered, 20 unique players, no OUT in XI), immediately re-run with `--submit` appended. **Do NOT ask the user for confirmation** — the user has pre-authorized this flow by setting up credentials and invoking `submit=1`.
5. **If the dry-run shows a problem** (OUT player in XI, structural gap, login error), surface the issue to the user and stop — don't push.
6. On submit, the script verifies non-error and non-redirect-to-/sign_in response. Report the HTTP status and final URL.

**Safety rules — non-negotiable:**

- Default to dry-run. Never POST without an explicit `--submit` flag.
- Refuse to submit if the computed XI contains any player tagged **OUT — травма** or **OUT — дискваліфікація**. Print which players blocked the submission and ask the user to override (`force=1`) only if they explicitly insist.
- Refuse to submit if the squad has fewer than 20 unique players or if XI/bench player IDs overlap.
- Print a one-line summary of the diff vs. currently saved lineup (player IDs entering/leaving XI) before sending.
- If `MANTRA_COOKIE` is missing or the GET to `/edit` redirects to `/users/sign_in`, the cookie is expired — instruct the user to refresh from DevTools, do NOT prompt for a password.

## Notes

- Mantra UPL `tournament_id` is `15`. Verify before continuing.
- Mantra position codes (same across leagues): **Por**, **Dc**, **Dd**, **Ds**, **E**, **M**, **C**, **T**, **W**, **A**, **Pc**.
- The UPL has 16 clubs and ~30 rounds total (2025/26 season runs 1 Aug 2025 → 29 May 2026).
- League `transfer_status: closed` means the user can't change roster — pick within what they have.
- **No probable-lineups site exists for UPL** — that's the core deviation from `-it` and the PL skill. The "predicted XI" is purely an inference from recent starts + injury/suspension cross-checks.
- If the user has rotation-heavy clubs (Шахтар often rotates 3–4 across matches due to European fixtures), the recent-form signal is noisy — say so explicitly in the output rather than over-trusting `3/3`.
- Translit pitfall: Mantra player names are typically Latin transliteration; UPL articles use Cyrillic. When matching, normalize via club + shirt_number when name match is ambiguous.
- Source rate-limits: `tribuna.com` and `transfermarkt.com` often refuse server-side fetches — don't rely on them as a primary source.

## Example invocation

User: `/mantra-team-pick-ua 123`

Expected: a single table of 20 rows + ~5–10 lines of commentary on module choice, gaps, fixture concentration, unverified clubs, and substitution map. Default lookback is 3 matches; user can override with `lookback=5`.
