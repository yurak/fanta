# frozen_string_literal: true

namespace :tm do
  # rake 'tm:dump_html[tm_id]'
  desc 'Dump raw TM HTML for given tm_id into spec/fixtures'
  task :dump_html, [:tm_id] => :environment do |_t, args|
    tm_id = args[:tm_id].to_s.strip
    abort "tm_id is required, rake 'tm:dump_html[569598]'" if tm_id.empty?

    url = "https://www.transfermarkt.com/player-path/profil/spieler/#{tm_id}"

    client = Players::Transfermarkt::BrowserClient.new
    html = client.fetch_html(url, headless: false, cache_key: "spec_player_#{tm_id}", force: true)

    dest_dir = Rails.root.join('spec/fixtures/tm')
    FileUtils.mkdir_p(dest_dir)
    dest_path = dest_dir.join("player_#{tm_id}.html")

    File.write(dest_path, html)
    puts "✅ Saved HTML to: #{dest_path}"
  rescue Players::Transfermarkt::CaptchaRequired => e
    warn "❌ Captcha again: #{e.message}"
  end
end
