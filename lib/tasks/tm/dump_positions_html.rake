# frozen_string_literal: true

namespace :tm do
  # rake 'tm:dump_positions_html[tm_id,year]'
  desc 'Dump TM positions HTML for given tm_id and year'
  task :dump_positions_html, %i[tm_id year] => :environment do |_t, args|
    tm_id = args[:tm_id].to_s.strip
    year  = args[:year].to_i
    abort "usage: rake 'tm:dump_positions_html[tm_id,year]'" if tm_id.empty? || year.zero?

    player = Player.new(tm_id: tm_id)
    url    = player.tm_position_path(year)

    client = Players::Transfermarkt::BrowserClient.new
    html   = client.fetch_html(url, headless: false, cache_key: "spec_positions_#{tm_id}_#{year}", force: true)

    dest_dir = Rails.root.join('spec/fixtures/tm')
    FileUtils.mkdir_p(dest_dir)
    dest_path = dest_dir.join("positions_#{tm_id}_#{year}.html")

    File.write(dest_path, html)
    puts "✅ Saved positions HTML to: #{dest_path}"
  end
end
