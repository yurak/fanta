# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
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

        log_cache("browser OPEN key=#{cache_key} headless=#{headless}")

        Playwright.create(playwright_cli_executable_path: playwright_cli_path) do |pw|
          browser = pw.chromium.launch(
            headless: headless,
            args: ['--disable-blink-features=AutomationControlled']
          )
          begin
            context = build_context(browser)
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
        return unless sourcepoint_page?(page)

        page.wait_for_timeout(800)
        frame = find_consent_frame(page, timeout)
        click_consent_buttons(page, [frame, page].compact)
      end

      def sourcepoint_page?(page)
        html = page.content
        html.include?('privacy-mgmt.com') || html.include?('sourcepoint') || html.include?('_sp_')
      end

      def find_consent_frame(page, timeout)
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        frame = nil

        while (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000 < timeout
          frame = page.frames.find { |f| consent_frame?(f) }
          break if frame

          page.wait_for_timeout(200)
        end

        frame
      end

      def consent_frame?(frame)
        url = frame.url.to_s
        url.include?('privacy-mgmt.com') || url.include?('sp-prod.net') || url.include?('ccpa.sp-prod.net')
      end

      def click_consent_buttons(page, targets)
        consent_button_selectors.each do |sel|
          targets.each do |ctx|
            loc = ctx.locator(sel)
            next unless loc.count.positive?

            begin
              loc.first.click(timeout: 1_000)
            rescue StandardError
              nil
            end
            page.wait_for_timeout(600)
          end
        end
      end

      def consent_button_selectors
        [
          'button:has-text("Accept")',
          'button:has-text("Accept all")',
          'button:has-text("I agree")',
          'button:has-text("Agree")',
          'button:has-text("Continue")',
          'button:has-text("OK")'
        ]
      end

      def safe_page_content(page, tries: 12)
        last_error = nil
        last_html  = nil

        tries.times do |idx|
          last_html, result = attempt_page_content(page, idx)
          return result if result
        rescue Playwright::Error => e
          last_error = e
          next if navigating_error?(e)

          raise
        end

        raise_content_error(last_html, last_error)
      end

      def attempt_page_content(page, idx)
        page.wait_for_timeout(800 + (idx * 250))
        html = page.content
        result = html.present? && !html.strip.empty? ? html : nil
        [html, result]
      end

      def navigating_error?(error)
        error.message.include?('page is navigating') || error.message.include?('Execution context was destroyed')
      end

      def raise_content_error(last_html, last_error)
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

      def build_context(browser)
        context = browser.new_context(
          userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
          storageState: STORAGE_PATH
        )
        context.add_init_script(script: "Object.defineProperty(navigator, 'webdriver', { get: () => undefined })")
        context.set_extra_http_headers(
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language' => 'en-US,en;q=0.5',
          'Upgrade-Insecure-Requests' => '1'
        )
        context
      end

      def prepare_page(page, url)
        page.goto(url)
        accept_sourcepoint_consent!(page)
      end

      def obtain_html(page, cache_key:)
        html = safe_page_content(page)

        if html.include?('Human Verification')
          log_cache('WAF challenge detected, waiting for auto-resolve...')
          html = wait_for_waf_resolution(page) || html
        end

        if html.include?('Human Verification') || html.include?('captcha')
          dump_debug(page, cache_key: cache_key)
          raise Players::Transfermarkt::CaptchaRequired,
                'Captcha required again. Re-run: bundle exec ruby public/script/tm_login.rb'
        end

        unless html.include?('data-header')
          dump_debug(page, cache_key: cache_key)
          raise RestClient::Exception, "Invalid TM page (no data-header) for key=#{cache_key}"
        end

        html
      end

      def wait_for_waf_resolution(page, max_wait_ms: 20_000)
        step_ms = 1_500
        elapsed = 0
        while elapsed < max_wait_ms
          page.wait_for_timeout(step_ms)
          elapsed += step_ms
          html = page.content
          log_cache("WAF waiting... #{elapsed / 1000}s")
          return html unless html.include?('Human Verification')
        end
        nil
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
