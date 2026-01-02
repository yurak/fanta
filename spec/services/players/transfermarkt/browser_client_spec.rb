require 'rails_helper'
require 'json'
require 'fileutils'
require 'playwright'

RSpec.describe Players::Transfermarkt::BrowserClient do
  subject(:client) { described_class.new }

  let(:tmp_dir) { Rails.root.join('tmp', 'tm_spec') }

  before do
    FileUtils.mkdir_p(tmp_dir)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe '#fetch_html (storage state)' do
    let(:url) { 'https://example.com/player' }

    context 'when storage state JSON is missing' do
      before do
        stub_const("#{described_class}::STORAGE_PATH", tmp_dir.join('missing_storage.json').to_s)
        FileUtils.rm_f(described_class::STORAGE_PATH)
      end

      it 'raises CaptchaRequired error' do
        expect do
          client.fetch_html(url, cache_key: nil, force: true, ttl: 0)
        end.to raise_error(Players::Transfermarkt::CaptchaRequired)
      end
    end
  end

  describe '#fetch_html (cache)' do
    let(:url)        { 'https://example.com/player' }
    let(:storage_fn) { tmp_dir.join('tm_storage_state.json').to_s }
    let(:cache_key)  { 'spec_player_cache' }
    let(:cache_path) { Rails.root.join('tmp', 'transfermarkt_cache', "#{cache_key}.html") }

    before do
      stub_const("#{described_class}::STORAGE_PATH", storage_fn)

      FileUtils.mkdir_p(File.dirname(storage_fn))
      File.write(storage_fn, { cookies: [] }.to_json)
    end

    context 'when cached html is fresh' do
      let(:cached_html) { '<html><body><div class="data-header">OK</div></body></html>' }

      before do
        FileUtils.mkdir_p(cache_path.dirname)
        File.write(cache_path, cached_html)
      end

      it 'does not call Playwright.create' do
        expect(Playwright).not_to receive(:create)

        client.fetch_html(url, cache_key: cache_key, ttl: 86_400)
      end

      it 'returns cached html content' do
        html = client.fetch_html(url, cache_key: cache_key, ttl: 86_400)

        expect(html).to eq(cached_html)
      end
    end

    context 'when cached html contains Human Verification' do
      let(:cached_html) { '<html>Human Verification</html>' }

      before do
        FileUtils.mkdir_p(cache_path.dirname)
        File.write(cache_path, cached_html)
      end

      it 'ignores cache and calls Playwright.create' do
        chromium = instance_double('Chromium')
        browser  = instance_double('Browser')
        context  = instance_double('BrowserContext')
        page     = instance_double('Page')

        allow(Playwright).to receive(:create)
                               .and_yield(double('PW', chromium: chromium))

        allow(chromium).to receive(:launch).and_return(browser)
        allow(browser).to receive(:new_context).and_return(context)
        allow(context).to receive(:set_extra_http_headers)
        allow(context).to receive(:add_cookies)
        allow(context).to receive(:new_page).and_return(page)
        allow(page).to receive(:goto)
        allow(client).to receive(:accept_sourcepoint_consent!).with(page)
        allow(client).to receive(:safe_page_content).with(page).and_return('<html>OK data-header</html>')
        allow(client).to receive(:dump_debug)
        allow(browser).to receive(:close)

        client.fetch_html(url, cache_key: cache_key, ttl: 86_400)

        expect(Playwright).to have_received(:create)
      end
    end
  end

  describe '#read_cache / #write_cache' do
    let(:path) { tmp_dir.join('cache.html') }

    it 'writes html to disk' do
      client.send(:write_cache, path, '<html>cache</html>')

      expect(File.exist?(path)).to be(true)
    end

    it 'reads fresh cache' do
      File.write(path, '<html>fresh</html>')

      result = client.send(:read_cache, path, 86_400)

      expect(result).to eq('<html>fresh</html>')
    end

    it 'returns nil when cache file is too old' do
      File.write(path, '<html>old</html>')
      old_time = 3.days.ago.to_time # ← важливо

      File.utime(old_time, old_time, path)

      result = client.send(:read_cache, path, 60)

      expect(result).to be_nil
    end

    it 'returns nil when cache contains Human Verification' do
      File.write(path, '<html>Human Verification</html>')

      result = client.send(:read_cache, path, 86_400)

      expect(result).to be_nil
    end
  end

  describe '#dump_debug' do
    let(:page) { instance_double('PlaywrightPage', content: '<html>debug</html>') }
    let(:key)  { 'spec_key' }
    let(:base) { Rails.root.join('tmp', "tm_debug_#{key}") }

    before do
      allow(page).to receive(:screenshot)
      allow(Rails.logger).to receive(:warn)

      client.send(:dump_debug, page, cache_key: key)
    end

    it 'writes debug html file' do
      expect(File.exist?("#{base}.html")).to be(true)
    end

    it 'takes screenshot' do
      expect(page).to have_received(:screenshot).with(path: "#{base}.png")
    end

    it 'logs warning with file paths' do
      expect(Rails.logger).to have_received(:warn)
                                .with("[TM][BrowserClient] debug dump: #{base}.html / #{base}.png")
    end
  end

  describe '#safe_page_content' do
    let(:page) { instance_double('PlaywrightPage') }

    before do
      allow(page).to receive(:wait_for_timeout)
    end

    context 'when stable html appears after retries' do
      before do
        allow(page).to receive(:content).and_return('', '<html><div class="data-header">OK</div></html>')
      end

      it 'returns html containing data-header' do
        html = client.send(:safe_page_content, page, tries: 3)

        expect(html).to include('data-header')
      end
    end

    context 'when page keeps navigating and then succeeds' do
      before do
        navigating_error = Playwright::Error.new(message: 'page is navigating')

        call_sequence = [
          -> { raise navigating_error },
          -> { '<html><div class="data-header">OK</div></html>' }
        ]

        allow(page).to receive(:content) do
          proc = call_sequence.shift || -> { '<html>fallback</html>' }
          proc.call
        end
      end

      it 'retries on navigation errors and eventually returns html' do
        html = client.send(:safe_page_content, page, tries: 3)

        expect(html).to include('data-header')
      end
    end
  end

  describe '#accept_sourcepoint_consent!' do
    let(:page) { instance_double('PlaywrightPage') }

    before do
      allow(page).to receive(:wait_for_timeout)
    end

    context 'when consent dialog exists on main page' do
      let(:empty_locator) { instance_double('Locator', count: 0) }
      let(:accept_locator) { instance_double('Locator') }

      before do
        allow(page).to receive(:content).and_return('<html>privacy-mgmt.com script here</html>')
        allow(page).to receive(:frames).and_return([])
        allow(page).to receive(:locator).and_return(empty_locator)
        allow(page).to receive(:locator).with('button:has-text("Accept")').and_return(accept_locator)
        allow(accept_locator).to receive(:count).and_return(1)
        first_double = instance_double('FirstNode')
        allow(accept_locator).to receive(:first).and_return(first_double)
        allow(first_double).to receive(:click)
      end

      it 'clicks accept button on the page' do
        client.send(:accept_sourcepoint_consent!, page)

        expect(page).to have_received(:locator).with('button:has-text("Accept")')
      end
    end

    context 'when consent dialog exists inside iframe' do
      let(:frame)          { instance_double('PlaywrightFrame') }
      let(:empty_locator)  { instance_double('Locator', count: 0) }
      let(:accept_locator) { instance_double('Locator') }

      before do
        allow(page).to receive(:content).and_return('<html>iframe privacy-mgmt.com</html>')
        allow(page).to receive(:frames).and_return([frame])
        allow(frame).to receive(:url).and_return('https://privacy-mgmt.com/someframe')
        allow(page).to receive(:locator).and_return(empty_locator)
        allow(frame).to receive(:locator).and_return(empty_locator)
        allow(frame).to receive(:locator).with('button:has-text("Accept all")').and_return(accept_locator)
        allow(accept_locator).to receive(:count).and_return(1)
        first_double = instance_double('FirstNode')
        allow(accept_locator).to receive(:first).and_return(first_double)
        allow(first_double).to receive(:click)
      end

      it 'clicks accept button inside iframe' do
        client.send(:accept_sourcepoint_consent!, page)

        expect(frame).to have_received(:locator).with('button:has-text("Accept all")')
      end
    end
  end
end
