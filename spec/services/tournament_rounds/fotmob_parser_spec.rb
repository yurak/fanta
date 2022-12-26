RSpec.describe TournamentRounds::FotmobParser do
  describe '#call' do
    subject(:parser) { described_class.new(tournament_url, tournament_round) }

    let(:response) { parser.call }
    let(:tournament_url) { nil }
    let(:tournament_round) { nil }
    let(:match_day_data) do
      [
        'Friday, 05 August 2022',
        [
          {
            'monthKey' => 'Friday, 05 August 2022',
            'round' => 1,
            'roundName' => 1,
            'pageUrl' => '/match/3903543/matchfacts/eintracht-frankfurt-vs-bayern-mnchen',
            'id' => '3903543',
            'home' => { 'name' => 'Eintracht Frankfurt', 'shortName' => 'Frankfurt', 'id' => '9810' },
            'away' => { 'name' => 'Bayern München', 'shortName' => 'Bayern München', 'id' => '9823' },
            'status' => { 'finished' => true, 'started' => true, 'cancelled' => false, 'scoreStr' => '1 - 6',
                          'startDateStr' => 'Aug 5, 2022', 'startDateStrShort' => '5. Aug.',
                          'reason' => { 'short' => 'FT', 'long' => 'Full-Time' } }
          }
        ]
      ]
    end

    context 'without tournament_url and tournament_round' do
      it 'returns empty array' do
        expect(response).to eq([])
      end
    end

    context 'with tournament_url and without tournament_round' do
      let(:tournament_url) { 'https://www.fotmob.com/leagues/54/matches/1.-bundesliga/by-round' }

      it 'returns match day data' do
        VCR.use_cassette 'fotmob_league_data' do
          expect(response.first[1].first).to eq(match_day_data)
        end
      end
    end

    context 'with tournament_url and with tournament_round with number nil' do
      let(:tournament_url) { 'https://www.fotmob.com/leagues/54/matches/1.-bundesliga/by-round' }
      let(:tournament_round) { create(:tournament_round, number: nil) }

      it 'returns match day data' do
        VCR.use_cassette 'fotmob_league_data' do
          expect(response.first[1].first).to eq(match_day_data)
        end
      end
    end

    context 'with tournament_url and with tournament_round with existed number' do
      let(:tournament_url) { 'https://www.fotmob.com/leagues/54/matches/1.-bundesliga/by-round' }
      let(:tournament_round) { create(:tournament_round, number: 2) }
      let(:round_match_day_data) do
        [
          'Friday, 12 August 2022',
          [
            {
              'monthKey' => 'Friday, 12 August 2022',
              'round' => 2,
              'roundName' => 2,
              'pageUrl' => '/match/3903555/matchfacts/sc-freiburg-vs-borussia-dortmund',
              'id' => '3903555',
              'home' => { 'name' => 'SC Freiburg', 'shortName' => 'Freiburg', 'id' => '8358' },
              'away' => { 'name' => 'Borussia Dortmund', 'shortName' => 'Dortmund', 'id' => '9789' },
              'status' => { 'finished' => true, 'started' => true, 'cancelled' => false, 'scoreStr' => '1 - 3',
                            'startDateStr' => 'Aug 12, 2022', 'startDateStrShort' => '12. Aug.',
                            'reason' => { 'short' => 'FT', 'long' => 'Full-Time' } }
            }
          ]
        ]
      end

      it 'returns match day data' do
        VCR.use_cassette 'fotmob_league_data_for_round' do
          expect(response.first).to eq(round_match_day_data)
        end
      end
    end
  end
end
