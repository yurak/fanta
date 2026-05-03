require 'fileutils'
require 'playwright'

ROOT = File.expand_path('../..', __dir__)
STORAGE_PATH = File.join(ROOT, 'tmp', 'tm_storage_state.json')

FileUtils.mkdir_p(File.dirname(STORAGE_PATH))
puts "Will save storage state to: #{STORAGE_PATH}"

cli_path = `which playwright`.strip
cli_path = 'npx playwright' if cli_path.empty?

Playwright.create(playwright_cli_executable_path: cli_path) do |pw|
  browser = pw.chromium.launch(
    headless: false,
    channel: 'chrome',
    args: ['--disable-blink-features=AutomationControlled']
  )
  context = browser.new_context(
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0'
  )
  context.add_init_script(script: "Object.defineProperty(navigator, 'webdriver', { get: () => undefined })")
  context.set_extra_http_headers(
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language' => 'en-US,en;q=0.5',
    'Upgrade-Insecure-Requests' => '1'
  )

  page = context.new_page
  page.goto('https://www.transfermarkt.com/')
  page.wait_for_timeout(2000)

  puts ''
  puts '👉 Step 1: Complete the Human Verification (captcha) if it appears in the browser window'
  puts '👉 Step 2: Navigate to any player page, e.g. https://www.transfermarkt.com/lionel-messi/profil/spieler/28003'
  puts '👉 Step 3: Wait until the player page FULLY loads (you see player name, stats, etc.)'
  puts '👉 Step 4: Come back here and press Enter'
  puts ''
  STDIN.gets

  cookies = context.cookies
  puts "🍪 Cookies captured: #{cookies.size}"
  cookies.each { |c| puts "   #{c[:name]} (#{c[:domain]})" }

  if cookies.empty?
    puts ''
    puts '⚠️  WARNING: No cookies were captured!'
    puts '   The captcha was likely not solved in the Playwright browser window.'
    puts '   Do NOT press Enter until you have solved captcha AND loaded a player page.'
    puts ''
    puts '👉 Press Enter again when done, or Ctrl+C to abort'
    STDIN.gets
    cookies = context.cookies
    puts "🍪 Cookies after second attempt: #{cookies.size}"
  end

  context.storage_state(path: STORAGE_PATH)
  puts ''
  puts "✅ Saved to #{STORAGE_PATH}"
  puts "   Cookies: #{cookies.size}, Origins: #{context.storage_state['origins'].size}"

  browser.close
end
