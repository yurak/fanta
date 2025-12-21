# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'playwright'

module Players
  module Transfermarkt
    class BrowserClient
      STORAGE_PATH = Rails.root.join('tmp/tm_storage_state.json').to_s

      def fetch_html(url, headless: true, cache_key: nil, force: false, ttl: 86_400)
        ensure_storage_state!

        path = cache_path(cache_key)

        if force
          log_cache("cache FORCED refresh key=#{cache_key}")
        else
          cached = read_cache(path, ttl)
          if cached
            log_cache("cache HIT key=#{cache_key}")
            return cached
          else
            log_cache("cache MISS key=#{cache_key}")
          end
        end

        state = JSON.parse(File.read(STORAGE_PATH))
        cookies = state.fetch('cookies', [])
        log_cache("browser OPEN key=#{cache_key} headless=#{headless}")

        Playwright.create(playwright_cli_executable_path: playwright_cli_path) do |pw|
          browser = pw.chromium.launch(headless: headless)
          begin
            context = browser.new_context
            context.add_cookies(cookies) if cookies.any?

            page = context.new_page
            page.goto(url)
            page.wait_for_load_state(state: 'domcontentloaded')
            page.wait_for_load_state(state: 'load')
            accept_sourcepoint_consent!(page)

            html = safe_page_content(page)
            unless html.include?('data-header')
              dump_debug(page, cache_key: cache_key)
            end

            if html.include?('Human Verification') || html.include?('captcha')
              raise Players::Transfermarkt::CaptchaRequired,
                    'Captcha required again. Re-run: bundle exec ruby public/script/tm_login.rb'
            end

            write_cache(path, html)
            log_cache("cache WRITE key=#{cache_key}")
            html
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

        path.read
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
            if loc.count.positive?
              loc.first.click(timeout: 1_000) rescue nil
              page.wait_for_timeout(600)
              return
            end
          end
        end
      end

      def safe_page_content(page, tries: 12)
        last_error = nil

        tries.times do |i|
          page.wait_for_timeout(800 + (i * 250))
          html = page.content

          return html if html.include?('data-header') || html.include?('profil/spieler')
          return html if html.length > 80_000
        rescue Playwright::Error => e
          last_error = e
          next if e.message.include?('page is navigating') || e.message.include?('Execution context was destroyed')
          raise
        end

        raise last_error || Playwright::Error.new('Unable to get stable page content')
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
    end
  end
end
