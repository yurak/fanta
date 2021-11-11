RSpec.describe TournamentRounds::FotmobParser do
  describe '#call' do
    subject(:parser) { described_class.new(tournament_url: tournament_url, tournament_round: tournament_round) }

    let(:response) { parser.call }
    let(:tournament_url) { nil }
    let(:tournament_round) { nil }
    let(:match_day_data) do
      [
        'Friday, 13 August 2021',
        [
          {
            'monthKey' => 'Friday, 13 August 2021',
            'round' => 1,
            'roundName' => 1,
            'pageUrl' => '/match/3624340/matchfacts/borussia-mgladbach-vs-bayern-münchen',
            'id' => '3624340',
            'home' => { 'name' => "Borussia M'Gladbach", 'shortName' => "M'gladbach", 'id' => '9788' },
            'away' => { 'name' => 'Bayern München', 'shortName' => 'Bayern München', 'id' => '9823' },
            'status' => { 'finished' => true, 'started' => true, 'cancelled' => false, 'scoreStr' => '1 - 1',
                          'startDateStr' => 'Aug 13, 2021', 'startDateStrShort' => '13. Aug.',
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
      let(:tournament_url) { 'https://www.fotmob.com/leagues?id=54&tab=matches&type=league' }

      it 'returns match day data' do
        VCR.use_cassette 'fotmob_league_data' do
          expect(response.first[1].first).to eq(match_day_data)
        end
      end
    end

    context 'with tournament_url and with tournament_round with number nil' do
      let(:tournament_url) { 'https://www.fotmob.com/leagues?id=54&tab=matches&type=league' }
      let(:tournament_round) { create(:tournament_round, number: nil) }

      it 'returns match day data' do
        VCR.use_cassette 'fotmob_league_data' do
          expect(response.first[1].first).to eq(match_day_data)
        end
      end
    end

    context 'with tournament_url and with tournament_round with existed number' do
      let(:tournament_url) { 'https://www.fotmob.com/leagues?id=54&tab=matches&type=league' }
      let(:tournament_round) { create(:tournament_round, number: 2) }
      let(:round_match_day_data) do
        [
          'Friday, 20 August 2021',
          [
            {
              'monthKey' => 'Friday, 20 August 2021',
              'round' => 2,
              'roundName' => 2,
              'pageUrl' => '/match/3624356/matchfacts/rb-leipzig-vs-vfb-stuttgart',
              'id' => '3624356',
              'home' => { 'name' => 'RB Leipzig', 'shortName' => 'RB Leipzig', 'id' => '178475' },
              'away' => { 'name' => 'VfB Stuttgart', 'shortName' => 'VfB Stuttgart', 'id' => '10269' },
              'status' => { 'finished' => true, 'started' => true, 'cancelled' => false, 'scoreStr' => '4 - 0',
                            'startDateStr' => 'Aug 20, 2021', 'startDateStrShort' => '20. Aug.',
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
