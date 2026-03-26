# spec/services/players/transfermarkt/browser_client_spec.rb
require 'rails_helper'
require 'json'
require 'fileutils'
require 'playwright'

class ChromiumDouble
  def launch(*); end
end

class BrowserDouble
  def new_context(*); end
  def close(*); end
end

class BrowserContextDouble
  def set_extra_http_headers(*); end
  def add_cookies(*); end
  def new_page(*); end
end

class PlaywrightPageDouble
  def goto(*); end
  def wait_for_timeout(*); end
  def content(*); end
  def frames(*); end
  def locator(*); end
  def screenshot(*); end
end

class LocatorDouble
  def count(*); end
  def first(*); end
end

class NodeDouble
  def click(*); end
end

class PlaywrightFrameDouble
  def url(*); end
  def locator(*); end
end

class PlaywrightApiDouble
  def chromium; end
end

RSpec.describe Players::Transfermarkt::BrowserClient do
  subject(:client) { described_class.new }

  let(:tmp_dir) { Rails.root.join('tmp/tm_spec') }

  before do
    FileUtils.mkdir_p(tmp_dir)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  def build_storage_state(path:, cookies: [])
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, { cookies: cookies }.to_json)
  end

  def stub_playwright_pipeline(html:)
    chromium = build_chromium_double
    browser, context, page = build_browser_stack(chromium)
    stub_page_content(page, html)

    [browser, context, page]
  end

  def build_chromium_double
    chromium = instance_double(ChromiumDouble)
    pw       = instance_double(PlaywrightApiDouble, chromium: chromium)

    allow(Playwright).to receive(:create).and_yield(pw)
    chromium
  end

  def build_browser_stack(chromium)
    browser = instance_double(BrowserDouble)
    context = instance_double(BrowserContextDouble)
    page    = instance_double(PlaywrightPageDouble)

    allow(chromium).to receive(:launch).and_return(browser)
    allow(browser).to receive(:new_context).and_return(context)
    allow(browser).to receive(:close)
    allow(context).to receive(:set_extra_http_headers)
    allow(context).to receive(:add_cookies)
    allow(context).to receive(:new_page).and_return(page)

    [browser, context, page]
  end

  def stub_page_content(page, html)
    allow(page).to receive(:goto)
    allow(page).to receive(:wait_for_timeout)
    allow(page).to receive(:content).and_return(html)
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
      build_storage_state(path: storage_fn)
    end

    context 'when cached html is fresh' do
      let(:cached_html) { '<html><body><div class="data-header">OK</div></body></html>' }

      before do
        FileUtils.mkdir_p(cache_path.dirname)
        File.write(cache_path, cached_html)
        allow(Playwright).to receive(:create)
      end

      it 'returns cached html content' do
        result = client.fetch_html(url, cache_key: cache_key, ttl: 86_400)

        expect(result).to eq(cached_html)
      end

      it 'does not open Playwright' do
        client.fetch_html(url, cache_key: cache_key, ttl: 86_400)

        expect(Playwright).not_to have_received(:create)
      end
    end

    context 'when cache is expired' do
      let(:fresh_html) { '<html><div class="data-header">fresh</div></html>' }

      before do
        FileUtils.mkdir_p(cache_path.dirname)
        File.write(cache_path, '<html>old</html>')
        old_time = Time.now.utc - (10 * 24 * 3600)
        File.utime(old_time, old_time, cache_path)
        stub_playwright_pipeline(html: fresh_html)
        allow(Rails.logger).to receive(:info)
      end

      it 'fetches fresh html via browser' do
        result = client.fetch_html(url, cache_key: cache_key, ttl: 86_400)

        expect(result).to eq(fresh_html)
      end
    end

    context 'when force: true is passed with fresh cache' do
      let(:cached_html) { '<html><div class="data-header">cached</div></html>' }
      let(:fresh_html)  { '<html><div class="data-header">fresh</div></html>' }

      before do
        FileUtils.mkdir_p(cache_path.dirname)
        File.write(cache_path, cached_html)
        stub_playwright_pipeline(html: fresh_html)
        allow(Rails.logger).to receive(:info)
      end

      it 'bypasses cache and fetches from browser' do
        result = client.fetch_html(url, cache_key: cache_key, ttl: 86_400, force: true)

        expect(result).to eq(fresh_html)
      end
    end

    context 'when page has no data-header (e.g. 502)' do
      let(:bad_html) { '<html><head><title>502 Bad Gateway</title></head><body></body></html>' }

      before do
        FileUtils.rm_f(cache_path)
        _browser, _context, page = stub_playwright_pipeline(html: bad_html)
        allow(page).to receive(:screenshot)
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
      end

      it 'raises RestClient::Exception' do
        expect do
          client.fetch_html(url, cache_key: cache_key, ttl: 86_400)
        end.to raise_error(RestClient::Exception)
      end

      it 'does not write invalid html to cache' do
        client.fetch_html(url, cache_key: cache_key, ttl: 86_400)
      rescue RestClient::Exception
        expect(File.exist?(cache_path)).to be(false)
      end
    end

    context 'when live page contains captcha' do
      let(:captcha_html) { '<html><div class="data-header">Human Verification</div></html>' }

      before do
        FileUtils.rm_f(cache_path)
        _browser, _context, page = stub_playwright_pipeline(html: captcha_html)
        allow(page).to receive(:screenshot)
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
      end

      it 'raises CaptchaRequired' do
        expect do
          client.fetch_html(url, cache_key: cache_key, ttl: 86_400)
        end.to raise_error(Players::Transfermarkt::CaptchaRequired)
      end
    end

    context 'when cached html contains Human Verification' do
      let(:cached_html) { '<html>Human Verification</html>' }
      let(:html_after)  { '<html><div class="data-header">OK</div></html>' }

      before do
        FileUtils.mkdir_p(cache_path.dirname)
        File.write(cache_path, cached_html)
        stub_playwright_pipeline(html: html_after)
        allow(Rails.logger).to receive(:info)
      end

      it 'ignores cache' do
        result = client.fetch_html(url, cache_key: cache_key, ttl: 86_400)

        expect(result).to eq(html_after)
      end

      it 'calls Playwright.create' do
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
      old_time = (Time.now.utc - (3 * 24 * 3600))

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
    let(:page) { instance_double(PlaywrightPageDouble, content: '<html>debug</html>') }
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
      expect(Rails.logger).to have_received(:warn).with("[TM][BrowserClient] debug dump: #{base}.html / #{base}.png")
    end
  end

  describe '#safe_page_content' do
    let(:page) { instance_double(PlaywrightPageDouble) }

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

    context 'when all tries are exhausted with empty content' do
      before do
        allow(page).to receive(:content).and_return('')
      end

      it 'raises StandardError' do
        expect do
          client.send(:safe_page_content, page, tries: 2)
        end.to raise_error(StandardError)
      end
    end

    context 'when page returns captcha html' do
      before do
        allow(page).to receive(:content).and_return('<html>Human Verification</html>')
      end

      it 'returns the html (captcha check is done by obtain_html)' do
        result = client.send(:safe_page_content, page, tries: 2)

        expect(result).to include('Human Verification')
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
    let(:page) { instance_double(PlaywrightPageDouble) }

    before do
      allow(page).to receive(:wait_for_timeout)
    end

    context 'when page has no sourcepoint elements' do
      before do
        allow(page).to receive(:content).and_return('<html>No consent here</html>')
      end

      it 'does nothing and does not raise' do
        expect do
          client.send(:accept_sourcepoint_consent!, page)
        end.not_to raise_error
      end
    end

    context 'when consent dialog exists on main page' do
      let(:empty_locator)  { instance_double(LocatorDouble, count: 0) }
      let(:accept_locator) { instance_double(LocatorDouble) }
      let(:first_node)     { instance_double(NodeDouble) }

      before do
        allow(page).to receive(:content).and_return('<html>privacy-mgmt.com script here</html>')
        allow(page).to receive(:frames).and_return([])
        allow(page).to receive(:locator).and_return(empty_locator)
        allow(page).to receive(:locator).with('button:has-text("Accept")').and_return(accept_locator)
        allow(accept_locator).to receive(:count).and_return(1)
        allow(accept_locator).to receive(:first).and_return(first_node)
        allow(first_node).to receive(:click)
      end

      it 'tries to click accept button on the page' do
        client.send(:accept_sourcepoint_consent!, page)

        expect(page).to have_received(:locator).with('button:has-text("Accept")')
      end
    end

    context 'when consent dialog exists inside iframe' do
      let(:frame)          { instance_double(PlaywrightFrameDouble) }
      let(:empty_locator)  { instance_double(LocatorDouble, count: 0) }
      let(:accept_locator) { instance_double(LocatorDouble) }
      let(:first_node)     { instance_double(NodeDouble) }

      before do
        allow(page).to receive(:content).and_return('<html>iframe privacy-mgmt.com</html>')
        allow(page).to receive(:frames).and_return([frame])
        allow(frame).to receive(:url).and_return('https://privacy-mgmt.com/someframe')
        allow(page).to receive(:locator).and_return(empty_locator)
        allow(frame).to receive(:locator).and_return(empty_locator)
        allow(frame).to receive(:locator).with('button:has-text("Accept all")').and_return(accept_locator)
        allow(accept_locator).to receive(:count).and_return(1)
        allow(accept_locator).to receive(:first).and_return(first_node)
        allow(first_node).to receive(:click)
      end

      it 'tries to click accept button inside iframe' do
        client.send(:accept_sourcepoint_consent!, page)

        expect(frame).to have_received(:locator).with('button:has-text("Accept all")')
      end
    end
  end
end
