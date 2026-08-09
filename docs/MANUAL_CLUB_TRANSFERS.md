# Manual Club Transfer Requests

How to create `ClubTransferRequest` records by hand from the Rails console when the automatic
Transfermarkt pipeline cannot do it.

## When to use this

The normal path is `rake 'club_transfers:import_history[from,to]'` → `ClubTransfers::HistoryImporter`
stores TM history in `club_transfers` → `ClubTransfers::RequestBuilder` turns the latest transfer into
a pending `ClubTransferRequest` shown on `/manage/club_transfer_requests`.

Go manual only when that path is unavailable:

- Transfermarkt is down / blocking us (it has gone dark for days at a time).
- TM has not published a move yet, but it is already official elsewhere.
- A one-off correction that has no TM transfer behind it.

Data source when TM is down: FotMob transfer pages, e.g.
<https://www.fotmob.com/en-GB/leagues/87/transfers/laliga> (`87` = LaLiga; swap the id for other
leagues).

## Step 1 — sync the local DB (optional but recommended)

Run `bin/db_pull` first so player/club ids you look up locally match production. Takes ~10 min
(SSH tunnel + `pg_dump` of ~500 MB + restore). It **drops and recreates** `mantra_development`.

Ids are stable between the dump and production, so the commands you compose locally can be pasted
into the production console — but re-check ownership (`teams`) on production, since the dump is a
point-in-time snapshot.

## Step 2 — find the players

Player `name` holds the **surname only**; the given name is in `first_name`. Always search by
surname, then disambiguate on `first_name` / `birth_date` / current club.

```ruby
Player.where('name ILIKE ?', '%Mangala%').includes(:club).each { |p| puts "#{p.id} | #{p.first_name} #{p.name} | #{p.birth_date} | club=#{p.club&.name}(#{p.club_id}) | tm=#{p.tm_id} | teams=#{p.teams.map(&:name).join('/')}" }
```

Accents are stripped in our data (`Núñez` → `Nunez`, `Bayındır` → `Bayindir`, `Angeliño` →
`Angelino`), so search the ASCII form. If a surname is too common, list the whole squad instead:

```ruby
Player.where(club_id: 90).order(:name).each { |p| puts "#{p.id} | #{p.first_name} #{p.name} | tm=#{p.tm_id}" }
```

Youth/reserve-team players (moves to `Celta Fortuna`, `Atlético Madrileño`, …) usually are not in the
DB at all — skip them.

## Step 3 — find the destination clubs

```ruby
Club.where('name ILIKE ? OR full_name ILIKE ?', '%getafe%', '%getafe%').each { |c| puts "#{c.id} | #{c.name} | #{c.full_name} | t#{c.tournament_id} | #{c.status}" }
Club.where(tournament_id: 5).order(:name).each { |c| puts "#{c.id} | #{c.name} | #{c.status}" }  # 5 = Spain
```

If the destination club is **not** in the DB (a second-division or foreign club we do not track),
pass `new_club_id: nil` and only set `new_club_name`. On confirm, `ClubTransfers::Applier` moves the
player to the `Outside` club and sells him from every fanta team that owns him.

## Step 4 — check what is already done

TM may have imported some of the moves already. A player who is *already sitting in the destination
club* needs nothing.

```ruby
[1949, 292, 13560].each do |id|
  pl = Player.find(id)
  puts "#{id} | #{pl.first_name} #{pl.name} | club=#{pl.club&.name}(#{pl.club_id}) | teams=#{pl.teams.map(&:name).join('/')}"
  puts "  reqs: " + ClubTransferRequest.where(player_id: id).order(:id).map { |r| "##{r.id} #{r.status} #{r.old_club_name}->#{r.new_club_name} #{r.start_date}" }.join(' ; ')
  puts "  transfers: " + pl.club_transfers.order(start_date: :desc).limit(2).map { |t| "#{t.start_date} ->#{t.new_club_name} loan=#{t.loan} tm=#{t.tm_transfer_id}" }.join(' ; ')
end
```

## Step 5 — create the requests

Helper (paste once per console session):

```ruby
def ctr(pid, ncid, ncn, date, loan: false); pl = Player.find(pid); r = ClubTransferRequest.create!(player: pl, old_club_id: pl.club_id, old_club_name: pl.club&.name, new_club_id: ncid, new_club_name: ncn, start_date: Date.parse(date), loan: loan, status: :pending); puts "##{r.id} #{pl.first_name} #{pl.name}: #{r.old_club_name} -> #{r.new_club_name}#{' (loan)' if r.loan} #{r.start_date} | #{r.teams_status}"; r; end
```

Arguments: `player_id`, `new_club_id` (or `nil`), `new_club_name`, `start_date`, `loan:`.

Real example — the batch created on 2026-08-08 from the FotMob LaLiga page:

```ruby
ctr(1949,  81,  'Getafe',            '2026-08-08', loan: true)   # Orel Mangala       Lyon -> Getafe
ctr(14434, nil, 'Burgos CF',         '2026-08-08')               # Alex Fores         Villarreal -> Burgos CF (club not in DB)
ctr(292,   87,  'Rayo Vallecano',    '2026-08-08', loan: true)   # Marash Kumbulla    Roma -> Rayo Vallecano
ctr(7583,  79,  'Elche',             '2026-08-08', loan: true)   # Facundo Buonanotte Brighton -> Elche
ctr(13560, 5,   'Fiorentina',        '2026-08-07', loan: true)   # Franco Mastantuono Real Madrid -> Fiorentina
ctr(12158, 78,  'Deportivo Alaves',  '2026-08-07')               # Nicolas Valentini  Fiorentina -> Alaves
ctr(2098,  77,  'Celta Vigo',        '2026-08-07', loan: true)   # Altay Bayindir     Man Utd -> Celta Vigo
ctr(1711,  6,   'Genoa',             '2026-08-07')               # Djibril Sow        Sevilla -> Genoa
ctr(2646,  80,  'Espanyol',          '2026-08-07', loan: true)   # Unai Nunez         Celta Vigo -> Espanyol
ctr(16700, 79,  'Elche',             '2026-08-07')               # Javi Morcillo      Atletico Madrid -> Elche
ctr(8644,  23,  'Bournemouth',       '2026-08-06')               # Juanlu Sanchez     Sevilla -> Bournemouth
ctr(13265, 88,  'Real Madrid',       '2026-08-06')               # Yan Diomande       RB Leipzig -> Real Madrid
ctr(12103, nil, 'Eldense',           '2026-08-06')               # Pau Cabanes        Villarreal -> Eldense (club not in DB)
ctr(1140,  404, 'Deportivo A Coruna','2026-08-06', loan: true)   # Angelino           Roma -> Deportivo A Coruna
```

Without the helper, the same thing longhand:

```ruby
pl = Player.find(1949)
ClubTransferRequest.create!(
  player:         pl,
  old_club_id:    pl.club_id,
  old_club_name:  pl.club&.name,
  new_club_id:    81,             # nil when the club is not in our DB
  new_club_name:  'Getafe',       # required
  tm_club_id:     nil,
  tm_transfer_id: nil,            # keep nil for manual rows — see notes
  start_date:     Date.new(2026, 8, 8),  # required
  loan:           true,
  status:         :pending
)
```

## Step 6 — verify, then confirm in the UI

```ruby
ClubTransferRequest.pending.includes(:player).order(:id).each { |r| puts "##{r.id} #{r.player.first_name} #{r.player.name}: #{r.old_club_name} -> #{r.new_club_name}#{' (loan)' if r.loan} | teams=#{r.teams_count} | #{r.teams_status}" }
```

`teams_status` tells you the blast radius: `:red` leaves the championship **and** is owned by teams,
`:yellow` leaves but is unowned, `:blue` stays in the championship and is owned, `:green` stays and is
unowned.

Confirm each row on `/manage/club_transfer_requests` — the controller runs `ClubTransfers::Applier`
(`Players::ClubChanger`, which sells the player from owning teams on a cross-tournament move) and only
then flips the status. Do **not** flip `status` by hand in the console: that skips the club change and
the sales entirely.

## Notes / gotchas

- **Leave `tm_transfer_id` nil.** The unique index `idx_ctr_unique_tm_transfer` is partial
  (`WHERE tm_transfer_id IS NOT NULL`), so nil rows never collide. More importantly,
  `ClubTransfers::HistoryImporter` deletes *pending* requests whose `tm_transfer_id` TM no longer
  lists — a nil keeps your manual row safe once TM comes back.
- Only `new_club_name` and `start_date` are validated. Everything else is optional, but fill
  `old_club_id` / `old_club_name` so the manage list renders the "from" side.
- FotMob icons: `⇄` = loan (`loan: true`), `→` = permanent (`loan: false`). "Free agent" as a
  destination means `new_club_id: nil`, `new_club_name: 'Free agent'`.
- `Applier` returns `:skipped` when the player is already in the destination club or already in
  `Outside`, so a duplicate request is harmless — but it still marks the request confirmed.
- Rejecting is safe and non-destructive: `/manage/club_transfer_requests` reject just sets
  `status: :rejected`.
