require 'rails_helper'

RSpec.describe Scores::Injectors::FotmobPage do
  subject(:page) { described_class.new(match, budget: budget) }

  let(:sleeper) { class_double(Kernel, sleep: nil) }
  let(:budget) { Scores::ScrapeBudget.new(sleeper: sleeper) }
  let(:match) do
    create(:tournament_match, source_match_id: '5837092',
                              page_url: '/matches/bradford-city-vs-peterborough-united/2fog42#5837092')
  end

  let(:body) { '<html>the match page</html>' }

  # every example drives the real fetch, so nothing may reach the network
  def stub_requests(&block)
    allow(RestClient::Request).to receive(:execute, &block)
  end

  def urls_requested
    requested = []
    stub_requests do |args|
      requested << args[:url]
      body
    end
    page.html
    requested
  end

  def stub_redirect_then(html)
    calls = 0
    stub_requests do
      calls += 1
      raise redirect if calls == 1

      html
    end
  end

  def headers_sent
    sent = nil
    stub_requests do |args|
      sent = args
      body
    end
    page.html
    sent
  end

  describe 'which address it asks for' do
    # The slug names the PAIRING, not the match: FotMob answers it with whichever meeting of those
    # two teams is newest, so a league fixture came back to us as a cup tie once the teams met
    # again. The id names the match, so it goes first.
    it 'asks for the match by its id' do
      expect(urls_requested).to eq(['https://www.fotmob.com/match/5837092'])
    end

    it 'does not also ask for the slug once the id answers' do
      expect(urls_requested.size).to eq(1)
    end

    it 'returns what the page gave back' do
      stub_requests { body }

      expect(page.html).to eq(body)
    end

    context 'with no id on file' do
      # the column is NOT NULL, so an unknown id reaches us as an empty string
      before { match.update!(source_match_id: '') }

      it 'falls back to the stored slug' do
        expect(urls_requested).to eq(["https://www.fotmob.com#{match.page_url}"])
      end
    end

    context 'with neither an id nor a slug' do
      before { match.update!(source_match_id: '', page_url: '') }

      it 'returns nothing' do
        stub_requests { body }

        expect(page.html).to be_nil
      end

      it 'does not call out at all' do
        expect(urls_requested).to be_empty
      end
    end
  end

  describe 'falling back to the slug' do
    before do
      calls = 0
      stub_requests do |args|
        calls += 1
        raise RestClient::ResourceNotFound if calls == 1

        args[:url]
      end
    end

    it 'reads the match through the slug when the id misses' do
      expect(page.html).to eq("https://www.fotmob.com#{match.page_url}")
    end

    it 'records no failure for a miss it recovered from' do
      page.html

      expect(page.failure).to be_nil
    end
  end

  describe 'when the id misses and there is no slug behind it' do
    before do
      match.update!(page_url: '')
      stub_requests { raise RestClient::ResourceNotFound }
    end

    it 'reports the miss rather than swallowing it' do
      page.html

      expect(page.failure).to eq(:not_found)
    end

    it 'returns nothing' do
      expect(page.html).to be_nil
    end
  end

  describe 'a moved page' do
    let(:new_path) { '/matches/red-bull-new-york-vs-los-angeles-fc/4vdlmar7' }
    let(:redirect) do
      response = instance_double(RestClient::Response, code: 308, headers: { location: new_path })
      RestClient::PermanentRedirect.new(response)
    end

    # only the slug is allowed to be rewritten by a redirect — see the id case below
    before do
      match.update!(source_match_id: '')
      stub_redirect_then(body)
    end

    it 'follows the redirect and reads the page' do
      expect(page.html).to eq(body)
    end

    it 'stores the new address so the next pass goes straight there' do
      page.html

      expect(match.reload.page_url).to eq("#{new_path}#5837092")
    end

    it 'gives up when the redirect carries no location' do
      locationless = RestClient::PermanentRedirect.new(instance_double(RestClient::Response, code: 308, headers: {}))
      stub_requests { raise locationless }

      expect(page.html).to be_nil
    end

    # one hop only: a site that redirects in a circle must not spin the fetcher
    it 'does not chase a redirect loop' do
      stub_requests { raise redirect }
      page.html

      expect(RestClient::Request).to have_received(:execute).twice
    end
  end

  # A redirect on the id address must not rewrite the slug: that slug is the fallback, and
  # overwriting it with wherever the id hop landed would destroy the only other way in.
  describe 'a redirect on the id address' do
    let(:redirect) do
      response = instance_double(RestClient::Response, code: 308, headers: { location: '/somewhere-else' })
      RestClient::PermanentRedirect.new(response)
    end

    before { stub_redirect_then(body) }

    it 'leaves the stored slug untouched' do
      stored = match.page_url
      page.html

      expect(match.reload.page_url).to eq(stored)
    end

    it 'falls through to the slug instead of following the hop' do
      expect(page.html).to eq(body)
    end
  end

  describe 'retrying' do
    let(:budget) { Scores::ScrapeBudget.new(limit: 30, sleeper: sleeper) }

    before { match.update!(source_match_id: '') }

    it 'retries a 5xx while the budget lasts' do
      stub_requests { raise RestClient::InternalServerError.new(nil, 500) }
      page.html

      expect(RestClient::Request).to have_received(:execute).exactly(3).times
    end

    it 'spends the budget on the backoff' do
      stub_requests { raise RestClient::InternalServerError.new(nil, 500) }
      page.html

      expect(budget.spent).to eq(15)
    end

    it 'does not retry a refusal' do
      stub_requests { raise RestClient::Forbidden }
      page.html

      expect(RestClient::Request).to have_received(:execute).once
    end

    it 'does not spend the budget on a refusal' do
      stub_requests { raise RestClient::Forbidden }
      page.html

      expect(budget.spent).to eq(0)
    end

    context 'when the budget is already spent' do
      before { budget.take(30) }

      it 'gives up after the first attempt' do
        stub_requests { raise RestClient::InternalServerError.new(nil, 500) }
        page.html

        expect(RestClient::Request).to have_received(:execute).once
      end
    end
  end

  describe 'what it calls a failure' do
    before { match.update!(source_match_id: '') }

    it 'treats a 404 as a stale address rather than a broken scraper' do
      stub_requests { raise RestClient::ResourceNotFound }
      page.html

      expect(page.failure).to eq(:not_found)
    end

    it 'treats a block as a health problem' do
      stub_requests { raise RestClient::Forbidden }
      page.html

      expect(page.failure).to eq(:health)
    end

    it 'treats a dropped connection as a health problem' do
      stub_requests { raise SocketError }
      page.html

      expect(page.failure).to eq(:health)
    end

    it 'records nothing when the page came back' do
      stub_requests { body }
      page.html

      expect(page.failure).to be_nil
    end
  end

  describe 'the request it sends' do
    it 'identifies as a browser, since FotMob refuses anything else' do
      expect(headers_sent[:headers][:user_agent]).to eq(described_class::USER_AGENT)
    end

    it 'does not wait on a hung connection forever' do
      expect(headers_sent[:timeout]).to eq(described_class::REQUEST_TIMEOUT)
    end
  end
end
