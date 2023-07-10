RSpec.describe TournamentRounds::FotmobParser do
  describe '#call' do
    subject(:parser) { described_class.new(tournament, tournament_round) }

    let(:response) { parser.call }
    let(:tournament) { create(:tournament) }
    let(:tournament_round) { nil }
    let(:match_day_data) do
      {
        "away" => {"id"=>"9876", "name"=>"Hellas Verona", "shortName"=>"Hellas Verona"},
        "home" => {"id"=>"8534", "name"=>"Empoli", "shortName"=>"Empoli"},
        "id" => "4230531",
        "pageUrl" => "/match/4230531/matchfacts/empoli-vs-hellas-verona",
        "round" => 1,
        "roundName" => 1,
        "status" => {"cancelled"=>false, "finished"=>false, "started"=>false, "utcTime"=>"2023-08-19T16:30:00.000Z"},
      }
    end

    context 'without tournament' do
      let(:tournament) { nil }

      it 'returns empty array' do
        expect(response).to eq([])
      end
    end

    context 'without source_id and tournament_round' do
      it 'returns empty array' do
        expect(response).to eq([])
      end
    end

    context 'with source_id and without tournament_round' do
      let(:tournament) { create(:tournament, source_id: 55) }

      it 'returns match day data' do
        VCR.use_cassette 'fotmob_league_data' do
          expect(response.first).to eq(match_day_data)
        end
      end
    end

    context 'with source_id and with tournament_round with number nil' do
      let(:tournament) { create(:tournament, source_id: 55) }
      let(:tournament_round) { create(:tournament_round, tournament: tournament, number: nil) }

      it 'returns match day data' do
        VCR.use_cassette 'fotmob_league_data' do
          expect(response.first).to eq(match_day_data)
        end
      end
    end

    context 'with source_id and with tournament_round with existed number' do
      let(:tournament) { create(:tournament, source_id: 55) }
      let(:tournament_round) { create(:tournament_round, tournament: tournament, number: 2) }
      let(:round_match_day_data) do
        {
          "away" => {"id"=>"8636", "name"=>"Inter", "shortName"=>"Inter"},
          "home" => {"id"=>"8529", "name"=>"Cagliari", "shortName"=>"Cagliari"},
          "id" => "4230541",
          "pageUrl" => "/match/4230541/matchfacts/cagliari-vs-inter",
          "round" => 2,
          "roundName" => 2,
          "status" => {"cancelled"=>false, "finished"=>false, "started"=>false, "utcTime"=>"2023-08-27T16:00:00.000Z"},
        }
      end

      it 'returns match day data' do
        VCR.use_cassette 'fotmob_league_data_for_round' do
          expect(response.first).to eq(round_match_day_data)
        end
      end
    end
  end
end
