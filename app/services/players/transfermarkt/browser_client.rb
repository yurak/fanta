# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength:
require 'json'
require 'fileutils'

module Players
  module Transfermarkt
    class BrowserClient
      STORAGE_PATH = Rails.root.join('tmp/tm_storage_state.json').to_s

      def fetch_html(url, headless: false, cache_key: nil, force: false, ttl: 86_400)
        require 'playwright'

        ensure_storage_state!

        path = cache_path(cache_key)
        cached = fetch_from_cache(path, cache_key: cache_key, force: force, ttl: ttl)
        return cached if cached

        cookies = load_cookies
        log_cache("browser OPEN key=#{cache_key} headless=#{headless}")

        Playwright.create(playwright_cli_executable_path: playwright_cli_path) do |pw|
          browser = pw.chromium.launch(headless: headless)
          begin
            context = build_context(browser, cookies)
            page    = context.new_page

            prepare_page(page, url)

            html = obtain_html(page, cache_key: cache_key)

            write_cache_and_log(path, html, cache_key: cache_key)
            html
          rescue
            debug_page(page, cache_key: cache_key)
            raise
          ensure
            browser.close
          end
        end
      end

      private

      def ensure_storage_state!
        return if File.exist?(STORAGE_PATH)

        raise Players::Transfermarkt::CaptchaRequired,
              "Missing storage state: #{STORAGE_PATH}. Run: bundle exec ruby public/script/tm_login.rb"
      end

      def playwright_cli_path
        path = `which playwright`.strip
        path = 'npx playwright' if path.empty?
        path
      end

      def cache_path(cache_key)
        return nil if cache_key.nil? || cache_key.to_s.strip.empty?

        Rails.root.join('tmp', 'transfermarkt_cache', "#{cache_key}.html")
      end

      def read_cache(path, ttl)
        return nil unless path&.exist?
        return nil if (Time.zone.now - path.mtime) > ttl

        content = path.read
        return nil if content.include?('Human Verification') || content.include?('captcha')

        content
      end

      def write_cache(path, html)
        return unless path

        FileUtils.mkdir_p(path.dirname)
        path.write(html)
      end

      def accept_sourcepoint_consent!(page, timeout: 8_000)
        html = page.content
        return unless html.include?('privacy-mgmt.com') || html.include?('sourcepoint') || html.include?('_sp_')

        page.wait_for_timeout(800)

        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        frame = nil

        while (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000 < timeout
          frame = page.frames.find do |f|
            u = f.url.to_s
            u.include?('privacy-mgmt.com') || u.include?('sp-prod.net') || u.include?('ccpa.sp-prod.net')
          end
          break if frame

          page.wait_for_timeout(200)
        end

        targets = [frame, page].compact

        targets.each do |ctx|
          [
            'button:has-text("Accept")',
            'button:has-text("Accept all")',
            'button:has-text("I agree")',
            'button:has-text("Agree")',
            'button:has-text("Continue")',
            'button:has-text("OK")'
          ].each do |sel|
            loc = ctx.locator(sel)
            next unless loc.count.positive?

            begin
              loc.first.click(timeout: 1_000)
            rescue
              nil
            end
            page.wait_for_timeout(600)
          end
        end
      end

      def safe_page_content(page, tries: 12)
        last_error = nil
        last_html  = nil

        tries.times do |i|
          page.wait_for_timeout(800 + (i * 250))
          html = page.content
          last_html = html

          return html if html.present? && !html.strip.empty?
        rescue Playwright::Error => e
          last_error = e
          next if e.message.include?('page is navigating') || e.message.include?('Execution context was destroyed')

          raise
        end

        if last_html&.include?('Human Verification') || last_html&.include?('captcha')
          raise Players::Transfermarkt::CaptchaRequired,
                'Captcha required again. Re-run: bundle exec ruby public/script/tm_login.rb'
        end

        raise last_error || StandardError.new('Unable to get stable page content')
      end

      def log_cache(message)
        Rails.logger.info("[TM][BrowserClient] #{message}")
      end

      def dump_debug(page, cache_key: nil)
        key  = cache_key.presence || Time.now.to_i
        base = Rails.root.join('tmp', "tm_debug_#{key}")

        File.write("#{base}.html", page.content)
        page.screenshot(path: "#{base}.png")

        Rails.logger.warn("[TM][BrowserClient] debug dump: #{base}.html / #{base}.png")
      end

      def fetch_from_cache(path, cache_key:, force:, ttl:)
        if force
          log_cache("cache FORCED refresh key=#{cache_key}")
          return nil
        end

        cached = read_cache(path, ttl)
        if cached
          log_cache("cache HIT key=#{cache_key}")
          cached
        else
          log_cache("cache MISS key=#{cache_key}")
          nil
        end
      end

      def load_cookies
        state = JSON.parse(File.read(STORAGE_PATH))
        state.fetch('cookies', [])
      end

      def build_context(browser, cookies)
        context = browser.new_context
        context.set_extra_http_headers(
          'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language' => 'en-US,en;q=0.5',
          'Upgrade-Insecure-Requests' => '1'
        )
        context.add_cookies(cookies) if cookies.any?
        context
      end

      def prepare_page(page, url)
        page.goto(url)
        accept_sourcepoint_consent!(page)
      end

      def obtain_html(page, cache_key:)
        html = safe_page_content(page)

        unless html.include?('data-header')
          dump_debug(page, cache_key: cache_key)
          raise RestClient::Exception, "Invalid TM page (no data-header) for key=#{cache_key}"
        end

        if html.include?('Human Verification') || html.include?('captcha')
          dump_debug(page, cache_key: cache_key)
          raise Players::Transfermarkt::CaptchaRequired,
                'Captcha required again. Re-run: bundle exec ruby public/script/tm_login.rb'
        end

        html
      end

      def write_cache_and_log(path, html, cache_key:)
        write_cache(path, html)
        log_cache("cache WRITE key=#{cache_key}") if path
      end

      def debug_page(page, cache_key:)
        dump_debug(page, cache_key: cache_key) if page
      rescue
        nil
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength
