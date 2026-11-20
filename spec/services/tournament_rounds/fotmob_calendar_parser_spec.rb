require 'rails_helper'

RSpec.describe TournamentRounds::FotmobCalendarParser do
  subject(:parse) { described_class.call(tournament) }

  let(:tournament) { create(:tournament, source_id: 47) }
  let(:match_data) do
    { 'id' => 5_795_363, 'roundName' => 1, 'pageUrl' => '/matches/arsenal-vs-coventry/x',
      'home' => { 'name' => 'Arsenal' }, 'away' => { 'name' => 'Coventry City' },
      'status' => { 'utcTime' => '2026-08-21T19:00:00Z', 'scoreStr' => '3 - 0' } }
  end

  def page(matches)
    payload = { props: { pageProps: { fixtures: { allMatches: matches } } } }.to_json
    "<html><body><script id=\"__NEXT_DATA__\">#{payload}</script></body></html>"
  end

  before { allow(RestClient::Request).to receive(:execute).and_return(page([match_data])) }

  it 'normalizes the match' do
    expect(parse.first).to include(source_match_id: '5795363', round_name: 1, home_name: 'Arsenal',
                                   away_name: 'Coventry City', score: '3 - 0')
  end

  it 'parses the kickoff as UTC' do
    expect(parse.first[:kickoff]).to eq(DateTime.parse('2026-08-21T19:00:00Z'))
  end

  it 'reads the league page, not the decommissioned API' do
    parse

    expect(RestClient::Request).to have_received(:execute)
      .with(hash_including(url: 'https://www.fotmob.com/leagues/47/matches'))
  end

  context 'without a source_id' do
    let(:tournament) { create(:tournament, source_id: nil) }

    it { is_expected.to eq([]) }

    it 'does not call out' do
      parse

      expect(RestClient::Request).not_to have_received(:execute)
    end
  end

  context 'when a match has no kickoff' do
    let(:match_data) do
      { 'id' => 1, 'home' => { 'name' => 'A' }, 'away' => { 'name' => 'B' }, 'status' => { 'utcTime' => nil } }
    end

    it { is_expected.to eq([]) }
  end

  # FotMob moved its league pages behind a per-league slug and answers the old address with a 308.
  # RestClient raises on that rather than following it, and the rescue turned every calendar import
  # into an empty one, silently.
  context 'when the league page has moved' do
    let(:redirect) do
      response = instance_double(RestClient::Response, headers: { location: '/leagues/47/overview/mls' })
      RestClient::PermanentRedirect.new(response)
    end

    before do
      call_count = 0
      allow(RestClient::Request).to receive(:execute) do
        call_count += 1
        raise redirect if call_count == 1

        page([match_data])
      end
    end

    it 'follows the redirect and parses what it finds' do
      expect(parse.first).to include(source_match_id: '5795363')
    end

    it 'asks the address the redirect names' do
      parse

      expect(RestClient::Request).to have_received(:execute)
        .with(hash_including(url: 'https://www.fotmob.com/leagues/47/overview/mls'))
    end

    context 'when the redirect carries no address' do
      let(:redirect) do
        RestClient::PermanentRedirect.new(instance_double(RestClient::Response, headers: {}))
      end

      it { is_expected.to eq([]) }
    end
  end

  context 'when FotMob blocks the request' do
    before { allow(RestClient::Request).to receive(:execute).and_raise(RestClient::Forbidden) }

    it { is_expected.to eq([]) }
  end

  context 'when the page has no parseable payload' do
    before { allow(RestClient::Request).to receive(:execute).and_return('<html>nope</html>') }

    it { is_expected.to eq([]) }
  end
end
