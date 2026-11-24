require 'rails_helper'

RSpec.describe Signups::BotDetector do
  let(:chrome) do
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' \
      'Chrome/131.0.0.0 Safari/537.36'
  end

  def detect(user_agent: chrome, honeypot: nil)
    described_class.new(user_agent: user_agent, honeypot: honeypot)
  end

  describe 'the honeypot' do
    # The field is off-screen, unfocusable and hidden from screen readers, so anything in it
    # was put there by something reading the DOM rather than the page.
    it 'refuses a request that filled it' do
      expect(detect(honeypot: 'spam')).to be_bot
    end

    it 'gives the honeypot as the reason' do
      expect(detect(honeypot: 'spam').reason).to eq('honeypot')
    end

    it 'ignores an empty string, which is what a browser submits' do
      expect(detect(honeypot: '')).not_to be_bot
    end

    # it must outrank the agent test: a bot that fixes its user agent is still caught
    it 'refuses even when the agent looks current' do
      expect(detect(user_agent: chrome, honeypot: 'spam')).to be_bot
    end
  end

  describe 'the user agent' do
    # Every string here was taken from a real sign-up POST in the nginx log.
    {
      'Internet Explorer 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; AOL 7.0; Windows NT 5.1; SV1)',
      'Internet Explorer 8' => 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0)',
      'a PowerPC Mac' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.0.1) Gecko/20021111',
      'Gecko 1.x' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en; rv:1.9.2.29pre) Gecko/20130101',
      'WebKit older than 537' => 'Mozilla/5.0 (X11; U; Linux; cs-CZ) AppleWebKit/523.15 (KHTML, like Gecko)',
      'WebKit from the 400s' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/419 (KHTML, like Gecko, Safari/419.3)'
    }.each do |label, agent|
      it "refuses #{label}" do
        expect(detect(user_agent: agent)).to be_bot
      end
    end

    # nginx writes these as \x22; the request itself carries a real quote
    it 'refuses an agent carrying a quote, which no browser sends' do
      expect(detect(user_agent: '"Mozilla/5.0 (Macintosh) AppleWebKit/537.36 Chrome/130.0.0.0')).to be_bot
    end

    it 'refuses Internet Explorer 9' do
      expect(detect(user_agent: 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.0; Trident/5.0)')).to be_bot
    end

    # Deliberately allowed: no request in two days of logs arrived without one, and the suite's own
    # sign-ups do not set it. The honeypot covers a bot that simply omits the header.
    it 'allows a missing agent rather than guessing' do
      expect(detect(user_agent: nil)).not_to be_bot
    end

    it 'names the browser in the reason, so the log can be read' do
      expect(detect(user_agent: 'Mozilla/4.0 (compatible; MSIE 6.0)').reason).to start_with('dead browser:')
    end
  end

  describe 'browsers people actually use' do
    # The agent rule is the one that could turn visitors away, so each of these is a real string
    # from the same logs, taken from traffic outside the bot's subnet.
    {
      'Chrome on Windows' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' \
                             '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      'Chrome on macOS' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
                           '(KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
      'Safari on macOS' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 ' \
                           '(KHTML, like Gecko) Version/17.6 Safari/605.1.15',
      'Safari on iPhone' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) ' \
                            'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Mobile/15E148 Safari/604.1',
      'Chrome on Android' => 'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 ' \
                             '(KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
      'Firefox' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:133.0) Gecko/20100101 Firefox/133.0',
      'Firefox on Android' => 'Mozilla/5.0 (Android 14; Mobile; rv:132.0) Gecko/132.0 Firefox/132.0',
      'Edge' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' \
                'Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0'
    }.each do |label, agent|
      it "lets #{label} through" do
        expect(detect(user_agent: agent)).not_to be_bot
      end
    end

    # `rv:1\.\d` must not swallow today's Firefox, whose version passed 100 long ago
    it 'does not mistake a three-digit Firefox version for Gecko 1.x' do
      expect(detect(user_agent: 'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0')).not_to be_bot
    end

    it 'reports no reason for a current browser' do
      expect(detect.reason).to be_nil
    end
  end
end
