# Log shipping to Grafana Cloud

Production logs are shipped to Grafana Cloud Loki (free tier: ~50 GB/month, 14-day retention) so they
are searchable off-box and do not have to be kept on the app server's 16 GB disk.

This is set up and running. The sections below are both the record of what is on the server and the
recipe for rebuilding it.

Server: Ubuntu 22.04, x86_64. Shipped: `/var/www/fanta/shared/log/production.log` and
`/var/log/nginx/*.log`. Agent: Grafana Alloy 1.19.2, enabled at boot.

## 1. Credentials

The portal shows them as a single Promtail-style URL with the credentials inlined — on the stack page
under Loki, or in Grafana under *Connections → Add new connection → Alloy*:

```
https://1781938:<token>@logs-prod-012.grafana.net/loki/api/v1/push
```

Alloy takes them apart. The first two are already in `config/alloy/fanta.alloy`:

| Value | This stack |
|---|---|
| Push URL | `https://logs-prod-012.grafana.net/loki/api/v1/push` |
| User (instance ID) | `1781938` |
| Token | generated in the portal; lives in `/etc/default/alloy`, never in git |

## 2. Install Alloy

```bash
sudo mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null
sudo apt-get update && sudo apt-get install -y alloy
```

## 3. Configure

Write the token **after** installing — the package ships its own `/etc/default/alloy`, and an existing
file makes `dpkg` stop at an interactive prompt (see Gotchas):

```bash
echo 'GRAFANA_CLOUD_TOKEN=<token>' | sudo tee -a /etc/default/alloy > /dev/null
echo 'CONFIG_FILE=/etc/alloy/config.alloy' | sudo tee -a /etc/default/alloy > /dev/null
sudo chmod 600 /etc/default/alloy
```

`CONFIG_FILE` is not optional: the systemd unit runs `alloy run $CUSTOM_ARGS … $CONFIG_FILE`, so
without it the agent starts with no pipeline at all.

Copy `config/alloy/fanta.alloy` from this repo to `/etc/alloy/config.alloy` (the endpoint and the user
id are already filled in there).

Alloy runs as its own user and has to read the logs. Grant that with an ACL on the log directory
rather than by adding `alloy` to the `ubuntu` group — the group route would hand it everything that
group owns, including the home directory, for no reason:

```bash
sudo apt-get install -y acl
sudo setfacl -R -m u:alloy:rX /var/www/fanta/shared/log
sudo setfacl -d -m u:alloy:rX /var/www/fanta/shared/log   # applies to files rotation creates later
sudo -u alloy head -c 60 /var/www/fanta/shared/log/production.log   # must succeed
```

Nginx logs are readable through the `adm` group, which the package already puts `alloy` in.

```bash
sudo systemctl enable --now alloy
```

## 4. Verify

```bash
journalctl -u alloy -n 50 --no-pager     # no auth or config errors
curl -s localhost:12345/metrics | grep -E '^loki_write_(sent_entries|dropped_entries)_total'
```

`sent_entries_total` climbing with `dropped_entries_total` at zero means the logs are reaching Loki —
check that from the server before hunting through the UI.

Then in Grafana → **Explore** → pick the data source whose name ends in `-logs` (the default is
Prometheus, which is the usual reason the screen looks empty):

```
{app="fanta", stream="rails"}
{app="fanta"} |= "[telegram] send failed"
```

The second query is the one worth an alert: it catches every Telegram notification that failed to
reach a user (see `TelegramBot::Sender#report`).

## 5. Disk, once logs are shipped

Both applied on 2026-09-09:

**The systemd journal is capped at 200 MB.** It held 777 MB because `SystemMaxUse` was unset:

```bash
sudo sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=200M/' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald && sudo journalctl --rotate && sudo journalctl --vacuum-size=200M
```

The restart is what applies the cap; `--vacuum-size` alone frees nothing, because it only deletes
*archived* journals.

**Local retention is 2 days** — `rotate 7` → `rotate 2` in `/etc/logrotate.d/fanta`, with Loki holding
14 days. `copytruncate` stays: the Alloy config accounts for it.

Net effect: the journal went 777 → 145 MB, but the Alloy binary takes 527 MB back, so the disk sits at
~91% (1.5 GB free) rather than the ~85% the cleanup alone would have given.

Still available if space gets tight: `/var/lib/snapd` (1.6 GB, five `core*` bases of which two are
probably in use), four installed kernel images, and `/var/www/fanta` (4.5 GB against 321 MB of
releases).

## Log format

`lograge` is enabled in production, so a request is one logfmt line instead of the three the default
logger writes:

```
method=GET path=/tournament_rounds/1 format=html controller=TournamentRoundsController action=show status=200 allocations=6606172 duration=2316.29 view=2289.78 db=11.28 user_id=1
```

That is both readable on the box and parseable in Loki, which turns queries into field filters:

```
{app="fanta"} | logfmt | duration > 1000
{app="fanta"} | logfmt | status >= 500
{app="fanta"} | logfmt | user_id = "1"
```

`user_id` is added through `config.lograge.custom_payload`; it is absent for anonymous requests.

One artifact worth knowing: a request that Devise short-circuits for an unauthenticated user logs
`status=0`. The redirect is produced by Warden after the controller instrumentation has ended, so the
status never reaches the payload. Everything the app itself renders or redirects reports a real code.

Our own log lines (`Rails.logger.warn("[telegram] …")` and friends) are untouched by lograge and keep
the `[request_id]` tag from `config.log_tags`.

## Gotchas met while setting this up

**The package prompts on `/etc/default/alloy`.** If that file already exists, `dpkg` stops at an
interactive conffile question, which a non-interactive shell cannot answer, and the install ends
half-configured. Recover with `sudo dpkg --configure -a --force-confdef --force-confnew`, then append
the token and `CONFIG_FILE` again.

**The binary is 527 MB.** Alloy is the full OpenTelemetry Collector distribution; on this disk that is
a third of the free space. Budget for it before installing.

**Check `~/.ssh` modes before touching users or groups.** On this box `authorized_keys` was `0664` and
had been since 2023, which `StrictModes` refuses; SSH kept working only because EC2 Instance Connect
served the keys instead. The moment that path failed, the file was the only one left and every key was
rejected — which looks exactly like a self-inflicted lockout from whatever you just ran.
`chmod 600 ~/.ssh/authorized_keys` fixed it, and authentication no longer depends on EC2 Instance
Connect.
