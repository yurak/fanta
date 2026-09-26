require 'rails_helper'

RSpec.describe Standings::FotmobParser do
  subject(:parse) { described_class.call(tournament) }

  let(:tournament) { create(:tournament, source_id: 441) }
  let(:row) do
    { 'idx' => 1, 'id' => 1_181_312, 'name' => 'Polissya Zhytomyr', 'played' => 6, 'wins' => 5,
      'draws' => 0, 'losses' => 1, 'scoresStr' => '14-5', 'pts' => 15, 'qualColor' => '#FFD908' }
  end

  def page(data)
    payload = { props: { pageProps: { table: [{ data: data }] } } }.to_json
    "<html><body><script id=\"__NEXT_DATA__\">#{payload}</script></body></html>"
  end

  before { allow(RestClient::Request).to receive(:execute).and_return(page({ 'table' => { 'all' => [row] } })) }

  it 'normalizes the row' do
    expect(parse.first).to eq(position: 1, fotmob_team_id: 1_181_312, team_name: 'Polissya Zhytomyr',
                              played: 6, wins: 5, draws: 0, losses: 1, goals_for: 14,
                              goals_against: 5, points: 15, zone_color: '#FFD908')
  end

  it 'reads the table page of the league in source_id' do
    parse

    expect(RestClient::Request).to have_received(:execute)
      .with(hash_including(url: 'https://www.fotmob.com/leagues/441/table'))
  end

  context 'with a composite table (conferences plus an overall one)' do
    let(:east) { row.merge('name' => 'Nashville SC') }
    let(:west) { row.merge('idx' => 1, 'name' => 'Vancouver Whitecaps') }
    let(:data) do
      { 'composite' => true,
        'tables' => [{ 'leagueName' => 'Eastern', 'table' => { 'all' => [east] } },
                     { 'leagueName' => 'Western', 'table' => { 'all' => [west] } },
                     { 'leagueName' => 'Supporters Shield', 'table' => { 'all' => [east, west] } }] }
    end

    before { allow(RestClient::Request).to receive(:execute).and_return(page(data)) }

    it 'takes the widest table so every club is present exactly once' do
      expect(parse.pluck(:team_name)).to eq(['Nashville SC', 'Vancouver Whitecaps'])
    end
  end

  context 'without a source_id' do
    let(:tournament) { create(:tournament, source_id: nil) }

    it { is_expected.to eq([]) }

    it 'does not call out' do
      parse

      expect(RestClient::Request).not_to have_received(:execute)
    end
  end

  context 'when FotMob answers with nothing usable' do
    before { allow(RestClient::Request).to receive(:execute).and_return('<html></html>') }

    it { is_expected.to eq([]) }
  end
end
