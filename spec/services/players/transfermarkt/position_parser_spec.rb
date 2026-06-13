# spec/services/players/transfermarkt/position_parser_spec.rb
require 'rails_helper'

RSpec.describe Players::Transfermarkt::PositionParser do
  describe '#call' do
    subject(:parser) { described_class.new(player, year) }

    let(:year)   { 2023 }
    let(:player) { create(:player, tm_id: '406040') }

    def build_game(season_id:, position_id:, is_national_game: false)
      {
        'gameInformation' => { 'seasonId' => season_id, 'isNationalGame' => is_national_game },
        'statistics' => { 'generalStatistics' => { 'positionId' => position_id } }
      }
    end

    def stub_cache_miss
      allow_any_instance_of(Pathname).to receive(:exist?).and_return(false)
      allow_any_instance_of(Pathname).to receive(:write)
      allow(FileUtils).to receive(:mkdir_p)
    end

    def stub_cache_hit(data)
      allow_any_instance_of(Pathname).to receive(:exist?).and_return(true)
      allow_any_instance_of(Pathname).to receive(:mtime).and_return(Time.zone.now)
      allow_any_instance_of(Pathname).to receive(:read).and_return(data.to_json)
    end

    def stub_api(body)
      rest_response = instance_double(RestClient::Response, body: body.to_json)
      allow(RestClient::Request).to receive(:execute).and_return(rest_response)
    end

    context 'when player is nil' do
      let(:player) { nil }

      it 'returns empty hash' do
        expect(parser.call).to eq({})
      end
    end

    context 'when player has no tm_id' do
      let(:player) { create(:player, tm_id: nil) }

      it 'returns empty hash' do
        expect(parser.call).to eq({})
      end
    end

    context 'when API returns performance data' do
      before do
        stub_cache_miss
        stub_api(
          'data' => {
            'performance' => [
              build_game(season_id: 2023, position_id: 13), # SS → FW x3
              build_game(season_id: 2023, position_id: 13),
              build_game(season_id: 2023, position_id: 13),
              build_game(season_id: 2023, position_id: 14), # CF → ST x2
              build_game(season_id: 2023, position_id: 14),
              build_game(season_id: 2023, position_id: 12), # RW → W
              build_game(season_id: 2023, position_id: 6),  # DM → DM (not WB)
              build_game(season_id: 2023, position_id: 8),  # LM → WB
              build_game(season_id: 2022, position_id: 13)  # different season — ignored
            ]
          }
        )
      end

      it 'returns a Hash' do
        expect(parser.call).to be_a(Hash)
      end

      it 'counts SS as FW' do
        expect(parser.call['FW']).to eq(3)
      end

      it 'counts CF as ST' do
        expect(parser.call['ST']).to eq(2)
      end

      it 'counts RW as W' do
        expect(parser.call['W']).to eq(1)
      end

      it 'counts DM (id=6) as DM, not WB' do
        expect(parser.call['DM']).to eq(1)
      end

      it 'counts LM (id=8) as WB' do
        expect(parser.call['WB']).to eq(1)
      end

      it 'ignores games from other seasons' do
        expect(parser.call.values.sum).to eq(8)
      end

      it 'calls the correct API URL' do
        parser.call
        expect(RestClient::Request).to have_received(:execute).with(
          hash_including(url: "https://www.transfermarkt.com/ceapi/performance-game/#{player.tm_id}")
        )
      end
    end

    context 'when game has nil positionId' do
      before do
        stub_cache_miss
        stub_api(
          'data' => {
            'performance' => [
              { 'gameInformation' => { 'seasonId' => 2023 }, 'statistics' => { 'generalStatistics' => {} } },
              build_game(season_id: 2023, position_id: 5)
            ]
          }
        )
      end

      it 'skips games with no positionId' do
        expect(parser.call).to eq('RB' => 1)
      end
    end

    context 'when game has unknown positionId' do
      before do
        stub_cache_miss
        stub_api(
          'data' => {
            'performance' => [
              build_game(season_id: 2023, position_id: 99),
              build_game(season_id: 2023, position_id: 5)
            ]
          }
        )
      end

      it 'skips unknown position IDs' do
        expect(parser.call).to eq('RB' => 1)
      end
    end

    context 'when cache is valid' do
      before do
        stub_cache_hit([build_game(season_id: 2023, position_id: 5)])
        allow(RestClient::Request).to receive(:execute)
      end

      it 'does not call the API' do
        parser.call
        expect(RestClient::Request).not_to have_received(:execute)
      end

      it 'uses cached data' do
        expect(parser.call).to eq('RB' => 1)
      end
    end

    context 'when games include national team matches' do
      before do
        stub_cache_miss
        stub_api(
          'data' => {
            'performance' => [
              build_game(season_id: 2023, position_id: 8),                                    # LM → WB (club)
              build_game(season_id: 2023, position_id: 5, is_national_game: true),            # RB national — ignored
              build_game(season_id: 2023, position_id: 5, is_national_game: true)             # RB national — ignored
            ]
          }
        )
      end

      it 'excludes national team games from position counts' do
        expect(parser.call).to eq('WB' => 1)
      end

      it 'does not count national team RB as RB' do
        expect(parser.call['RB']).to be_nil
      end
    end

    context 'when API returns no performance data' do
      before do
        stub_cache_miss
        stub_api('data' => {})
      end

      it 'returns empty hash' do
        expect(parser.call).to eq({})
      end
    end
  end
end
