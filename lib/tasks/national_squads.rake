namespace :national_squads do
  # rake 'national_squads:check'                       — newest squad list in config/mantra/national_squads
  # rake 'national_squads:check[euro_2028_squads.csv]' — a particular one
  #
  # Prints one block per team whose squad has moved since we last wrote the list down, naming who
  # left and who arrived, with the club and birth date of each arrival so the row can be added.
  # Silent for a team that matches. Works for any tournament: the CSV is the only thing tied to one.
  desc 'Compare the squads we carry against the ones Wikipedia lists now'
  task :check, [:file] => :environment do |_t, args|
    path = NationalSquads::SquadList.path(args[:file])
    abort "no squad list found in #{NationalSquads::SquadList::DIR}" unless path

    rows = CSV.read(path, headers: true)
    by_team = rows.group_by { |row| row['team'] }
    puts "#{File.basename(path)}: #{rows.size} rows, #{by_team.size} teams"

    pages = NationalSquads::WikiFetcher.call(by_team.keys)
    changed = by_team.sort.count do |team, team_rows|
      lines = squad_report(team, team_rows, pages[team])
      lines.each { |line| puts line }
      lines.any?
    end

    puts "\nteams that moved: #{changed} of #{by_team.size}"
  end

  # The lines describing one team, empty when nothing moved. A team we could not read is reported
  # too: silence must never be mistaken for "nothing changed".
  def squad_report(team, rows, page)
    return ["\n#{team}: article not found"] if page.nil?

    theirs = NationalSquads::WikiParser.call(page[:wikitext])
    return ["\n#{team}: no squad section"] if theirs.empty?

    result = NationalSquads::Comparer.call(team, rows.pluck('player'), theirs)
    return [] unless result.changed?

    header = "\n#{team}  (ours #{result.ours_count} / wiki #{result.theirs_count}, " \
             "edited #{page[:edited_at].to_s[0, 16]})"
    [header] + result.gone.map { |name| "    gone:    #{name}" } + result.arrived.map { |p| joined_line(p) }
  end

  def joined_line(player)
    "    joined:  #{player[:name]}  [#{player[:position]}, #{player[:club]}, #{player[:birth_date]}]"
  end
end
