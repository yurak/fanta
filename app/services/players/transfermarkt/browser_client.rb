# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'playwright'

module Players
  module Transfermarkt
    class BrowserClient
      STORAGE_PATH = Rails.root.join('tmp', 'tm_storage_state.json').to_s

      def fetch_html(url, headless: true, cache_key: nil, force: false, ttl: 86_400)
        ensure_storage_state!

        path = cache_path(cache_key)

        unless force
          cached = read_cache(path, ttl)
          if cached
            log_cache("cache HIT key=#{cache_key}")
            return cached
          else
            log_cache("cache MISS key=#{cache_key}")
          end
        else
          log_cache("cache FORCED refresh key=#{cache_key}")
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

            html = safe_page_content(page)

            if html.include?('Human Verification') || html.include?('captcha')
              raise Players::Transfermarkt::CaptchaRequired,
                    "Captcha required again. Re-run: bundle exec ruby public/script/tm_login.rb"
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
        return nil if (Time.now - path.mtime) > ttl

        path.read
      end

      def write_cache(path, html)
        return unless path

        FileUtils.mkdir_p(path.dirname)
        path.write(html)
      end

      def safe_page_content(page, tries: 8)
        last_error = nil

        tries.times do |i|
          begin
            page.wait_for_timeout(800 + i * 250)
            html = page.content
            return html if html && !html.empty?
          rescue Playwright::Error => e
            last_error = e
            if e.message.include?('page is navigating') || e.message.include?('Execution context was destroyed')
              next
            end
            raise
          end
        end

        raise last_error || Playwright::Error.new('Unable to get stable page content')
      end

      def log_cache(message)
        Rails.logger.info("[TM][BrowserClient] #{message}")
      end
    end
  end
end
