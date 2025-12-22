require 'fileutils'
require 'playwright'

ROOT = File.expand_path('../..', __dir__)
STORAGE_PATH = File.join(ROOT, 'tmp', 'tm_storage_state.json')

FileUtils.mkdir_p(File.dirname(STORAGE_PATH))
puts "Will save storage state to: #{STORAGE_PATH}"

cli_path = `which playwright`.strip
cli_path = 'npx playwright' if cli_path.empty?

Playwright.create(playwright_cli_executable_path: cli_path) do |pw|
  browser = pw.chromium.launch(headless: false)
  context = browser.new_context
  context.set_extra_http_headers(
    'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language' => 'en-US,en;q=0.5',
    'Upgrade-Insecure-Requests' => '1'
  )

  page = context.new_page
  page.goto('https://www.transfermarkt.com/')
  page.wait_for_timeout(1500)

  puts "👉 Complete the Human Verification (captcha) if it appears"
  puts "👉 Then open any player page in the same browser window"
  puts "👉 Come back here and press Enter to save the session"
  STDIN.gets

  context.storage_state(path: STORAGE_PATH)
  puts "✅ Saved! File exists? #{File.exist?(STORAGE_PATH)}"

  browser.close
end
