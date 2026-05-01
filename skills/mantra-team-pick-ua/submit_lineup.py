#!/usr/bin/env python3
"""
Submit a Mantra Football lineup via the authenticated form endpoint.

Usage (called from the mantra-team-pick-ua skill):

    submit_lineup.py --team-id 874 \\
                     --module 3-5-1-1 \\
                     --xi 14443,8222,14299,14266,12620,8203,2249,4582,7125,10771,4016 \\
                     --bench 11232,14726,14297,8205,10772,5004,8198,9533,8217 \\
                     [--lineup-id 139114] \\
                     [--dry-run | --submit]

Auth precedence (first one found wins):
  1. MANTRA_COOKIE env var — full Cookie header (skip login)
  2. MANTRA_EMAIL + MANTRA_PASSWORD env vars (login flow)
  3. Credentials file at $MANTRA_CREDENTIALS or ~/.config/mantra/credentials
     Format (KEY=VALUE, # comments allowed):
        email=you@example.com
        password=secret
     File mode must be 0600 (chmod 600 ~/.config/mantra/credentials).

Default mode is --dry-run: prints exactly what would be POSTed and exits 0
without sending. Pass --submit to actually push.
"""

import argparse
import http.cookiejar
import os
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path
from urllib.error import HTTPError

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36")
BASE = "https://mantrafootball.org"

MODULE_MAP = {
    "3-4-3": 1, "3-4-1-2": 2, "3-4-2-1": 3, "3-5-2": 4, "3-5-1-1": 5,
    "4-3-3": 6, "4-3-1-2": 7, "4-4-2": 8, "4-1-4-1": 9, "4-4-1-1": 10,
    "4-2-3-1": 11, "4-3-2-1": 12,
}

DEFAULT_CRED_PATHS = [
    Path.home() / ".config" / "mantra" / "credentials",
    Path.home() / ".mantra-credentials",
]


def load_credentials():
    """Return (email, password) or None. Order: env vars → MANTRA_CREDENTIALS file → defaults."""
    e, p = os.environ.get("MANTRA_EMAIL"), os.environ.get("MANTRA_PASSWORD")
    if e and p:
        return e, p
    paths = []
    if (env := os.environ.get("MANTRA_CREDENTIALS")):
        paths.append(Path(env).expanduser())
    paths += DEFAULT_CRED_PATHS
    for path in paths:
        if not path.is_file():
            continue
        mode = path.stat().st_mode & 0o777
        if mode & 0o077:
            print(f"⚠ {path} mode is {oct(mode)} — recommend `chmod 600 {path}` "
                  f"(continuing anyway).", file=sys.stderr)
        kv = {}
        for line in path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            kv[k.strip().lower()] = v.strip().strip('"').strip("'")
        # Accept common aliases — Mantra logs in by email, but the file may use login/user/etc.
        e = kv.get("email") or kv.get("user_login") or kv.get("login") or kv.get("user") or kv.get("username")
        p = kv.get("password") or kv.get("user_password") or kv.get("pass") or kv.get("pwd")
        if e and p:
            return e, p
    return None


class Session:
    def __init__(self):
        self.jar = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self.jar)
        )

    def use_cookie_header(self, header):
        """Inject a raw Cookie header value (semicolon-separated key=value pairs)."""
        # urllib lets us set Cookie directly per-request; simpler than synthesizing CookieJar entries.
        self._raw_cookie = header
        # Disable jar to avoid mixing
        self.opener = urllib.request.build_opener()

    def request(self, method, path, data=None):
        url = path if path.startswith("http") else BASE + path
        headers = {"User-Agent": UA, "Accept": "text/html"}
        if hasattr(self, "_raw_cookie"):
            headers["Cookie"] = self._raw_cookie
        if data is not None:
            headers["Content-Type"] = "application/x-www-form-urlencoded"
            headers["Origin"] = BASE
            body = data.encode() if isinstance(data, str) else data
        else:
            body = None
        req = urllib.request.Request(url, data=body, method=method, headers=headers)
        try:
            resp = self.opener.open(req, timeout=30)
            return resp.status, resp.geturl(), resp.read().decode("utf-8", errors="replace")
        except HTTPError as e:
            return e.code, getattr(e, "url", url), e.read().decode("utf-8", errors="replace")

    def login(self, email, password):
        """Devise login: GET form → scrape CSRF → POST credentials."""
        status, _, html = self.request("GET", "/users/sign_in")
        if status != 200:
            sys.exit(f"login: GET /users/sign_in → HTTP {status}")
        m = re.search(r'name="authenticity_token"\s+value="([^"]+)"', html) or \
            re.search(r'value="([^"]+)"\s+name="authenticity_token"', html)
        if not m:
            sys.exit("login: authenticity_token not found on sign_in form")
        token = m.group(1)
        body = urllib.parse.urlencode([
            ("utf8", "✓"),
            ("authenticity_token", token),
            ("user[email]", email),
            ("user[password]", password),
            ("user[remember_me]", "1"),
            ("commit", "Log in"),
        ])
        status, final_url, html = self.request("POST", "/users/sign_in", data=body)
        # On success, Devise 302→/, on failure renders /users/sign_in 200 with "Invalid Email or password"
        if status == 200 and "/users/sign_in" in final_url:
            sys.exit("login: invalid credentials (got rendered sign-in page back).")
        if status >= 400:
            sys.exit(f"login: HTTP {status} on POST /users/sign_in")
        # Verify session cookie present
        names = {c.name for c in self.jar}
        if "_fanta_session" not in names:
            sys.exit("login: no _fanta_session cookie after POST. Devise behaviour changed?")


def discover_lineup_id(sess, team_id):
    """
    Walk: /api/teams/{tid}.json → league_id;
          /api/leagues/{lid}.json → link=/tours/{tour_id};
          /tours/{tour_id} (HTML) → find /matches/N near /teams/{tid};
          /matches/{mid} → /teams/{tid}/lineups/{lineup_id}/edit.
    """
    import json
    status, _, body = sess.request("GET", f"/api/teams/{team_id}.json")
    if status != 200:
        sys.exit(f"discover: /api/teams/{team_id}.json → HTTP {status}")
    league_id = json.loads(body)["data"]["league_id"]

    status, _, body = sess.request("GET", f"/api/leagues/{league_id}.json")
    if status != 200:
        sys.exit(f"discover: /api/leagues/{league_id}.json → HTTP {status}")
    link = json.loads(body)["data"].get("link", "")
    m = re.match(r"/tours/(\d+)", link)
    if not m:
        sys.exit(f"discover: league {league_id} has no /tours/N link (got {link!r})")
    tour_id = m.group(1)

    status, _, html = sess.request("GET", f"/tours/{tour_id}")
    if status != 200:
        sys.exit(f"discover: /tours/{tour_id} → HTTP {status}")
    # Each match block contains team links — find match whose block mentions our team_id.
    match_id = None
    for mid in sorted(set(re.findall(r"/matches/(\d+)", html))):
        # Look 1500 chars in either direction of /matches/{mid} for /teams/{team_id}
        for chunk in re.findall(rf".{{0,1500}}/matches/{mid}.{{0,1500}}", html, re.S):
            if re.search(rf"/teams/{team_id}\b", chunk):
                match_id = mid
                break
        if match_id:
            break
    if not match_id:
        sys.exit(f"discover: no match in tour {tour_id} found for team {team_id}. Pass --lineup-id.")

    status, _, html = sess.request("GET", f"/matches/{match_id}")
    if status != 200:
        sys.exit(f"discover: /matches/{match_id} → HTTP {status}")
    m = re.search(rf"/teams/{team_id}/lineups/(\d+)", html)
    if not m:
        sys.exit(f"discover: match {match_id} has no lineup link for team {team_id}.")
    return m.group(1)


def parse_edit_page(html):
    """Extract csrf-meta, form authenticity_token, tour_id, and 20 slot IDs from the edit HTML."""
    csrf = re.search(r'<meta name="csrf-token" content="([^"]+)"', html)
    auth = (re.search(r'name="authenticity_token"\s+value="([^"]+)"', html)
            or re.search(r'value="([^"]+)"\s+name="authenticity_token"', html))
    tour = re.search(r'value="(\d+)"[^>]*name="lineup\[tour_id\]"', html)
    if not (csrf and auth and tour):
        sys.exit("Failed to parse edit page (csrf/auth_token/tour_id missing). Session expired?")
    slots = []
    for n in range(20):
        sid = re.search(rf'value="(\d+)"[^>]*name="lineup\[match_players_attributes\]\[{n}\]\[id\]"', html)
        pos = re.search(rf'value="([^"]*)"[^>]*name="lineup\[match_players_attributes\]\[{n}\]\[real_position\]"', html)
        if not sid:
            sys.exit(f"Slot {n} match_player id missing from edit page.")
        slots.append({"slot_id": sid.group(1), "real_position": pos.group(1) if pos else None})
    return {
        "csrf_meta": csrf.group(1),
        "auth_token": auth.group(1),
        "tour_id": tour.group(1),
        "slots": slots,
    }


def build_payload(parsed, module_id, xi, bench):
    if len(xi) != 11:
        sys.exit(f"XI must have 11 players, got {len(xi)}")
    if len(bench) != 9:
        sys.exit(f"Bench must have 9 players, got {len(bench)}")
    fields = [
        ("commit", "Confirm squad"),
        ("utf8", "✓"),
        ("_method", "patch"),
        ("authenticity_token", parsed["auth_token"]),
        ("lineup[team_module_id]", str(module_id)),
        ("lineup[tour_id]", parsed["tour_id"]),
    ]
    for i, pid in enumerate(xi):
        slot = parsed["slots"][i]
        if not slot["real_position"]:
            sys.exit(f"Slot {i} has no real_position — module mismatch?")
        fields += [
            (f"lineup[match_players_attributes][{i}][real_position]", slot["real_position"]),
            (f"lineup[match_players_attributes][{i}][round_player_id]", str(pid)),
            (f"lineup[match_players_attributes][{i}][id]", slot["slot_id"]),
        ]
    for j, pid in enumerate(bench):
        n = 11 + j
        slot = parsed["slots"][n]
        fields += [
            (f"lineup[match_players_attributes][{n}][round_player_id]", str(pid)),
            (f"lineup[match_players_attributes][{n}][id]", slot["slot_id"]),
        ]
    return urllib.parse.urlencode(fields)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--team-id", required=True, type=int)
    ap.add_argument("--lineup-id", type=int, help="If omitted, auto-discovered from /teams/{id}")
    ap.add_argument("--module", required=True, help="e.g. 3-5-1-1")
    ap.add_argument("--xi", required=True, help="comma-separated 11 round_player_ids")
    ap.add_argument("--bench", required=True, help="comma-separated 9 round_player_ids")
    grp = ap.add_mutually_exclusive_group()
    grp.add_argument("--dry-run", action="store_true", default=True)
    grp.add_argument("--submit", action="store_true")
    args = ap.parse_args()

    if args.module not in MODULE_MAP:
        sys.exit(f"Unknown module {args.module}. Valid: {sorted(MODULE_MAP)}")
    module_id = MODULE_MAP[args.module]

    xi = [int(x) for x in args.xi.split(",") if x]
    bench = [int(x) for x in args.bench.split(",") if x]
    if set(xi) & set(bench):
        sys.exit(f"Player IDs in both XI and bench: {set(xi) & set(bench)}")
    if len(set(xi + bench)) != 20:
        sys.exit("XI + bench must be 20 unique players.")

    sess = Session()
    cookie = os.environ.get("MANTRA_COOKIE", "").strip()
    if cookie:
        sess.use_cookie_header(cookie)
        print("auth        : MANTRA_COOKIE env var")
    else:
        creds = load_credentials()
        if not creds:
            sys.exit("No auth available. Set MANTRA_COOKIE, or MANTRA_EMAIL+MANTRA_PASSWORD, "
                     "or create ~/.config/mantra/credentials (chmod 600) with email=…/password=…")
        sess.login(*creds)
        print(f"auth        : logged in as {creds[0]}")

    lineup_id = args.lineup_id or discover_lineup_id(sess, args.team_id)
    edit_url = f"/teams/{args.team_id}/lineups/{lineup_id}/edit?team_module_id={module_id}"
    status, _, html = sess.request("GET", edit_url)
    if status != 200 or "csrf-token" not in html:
        sys.exit(f"GET {edit_url} → HTTP {status}; auth likely failed.")

    parsed = parse_edit_page(html)
    body = build_payload(parsed, module_id, xi, bench)

    print(f"team_id     : {args.team_id}")
    print(f"lineup_id   : {lineup_id}")
    print(f"module      : {args.module} (id={module_id})")
    print(f"tour_id     : {parsed['tour_id']}")
    print(f"XI slots    : {[(s['real_position'], xi[i]) for i, s in enumerate(parsed['slots'][:11])]}")
    print(f"Bench       : {bench}")
    print(f"payload size: {len(body)} bytes")

    if not args.submit:
        print("\n[DRY RUN] not submitting. Re-run with --submit to push.")
        return 0

    submit_url = f"/teams/{args.team_id}/lineups/{lineup_id}"
    status, final_url, resp = sess.request("POST", submit_url, data=body)
    print(f"\nPOST {submit_url} → HTTP {status}, landed: {final_url}")
    if status >= 400 or "/users/sign_in" in final_url:
        print(resp[:500])
        return 1
    if "alert-danger" in resp or "field_with_errors" in resp:
        print("⚠ response contains error markers — verify in browser.")
        m = re.search(r'class="[^"]*alert[^"]*"[^>]*>([^<]+)', resp)
        if m:
            print(m.group(1).strip())
        return 1
    print("✓ submitted.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
