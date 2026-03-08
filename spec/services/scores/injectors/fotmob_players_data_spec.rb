RSpec.describe Scores::Injectors::FotmobPlayersData do
  subject(:result) { described_class.call(match_data) }

  let(:match_data) do
    { 'playerStats' => player_stats, 'matchFacts' => { 'events' => { 'events' => events } } }
  end

  let(:events) { [] }

  let(:player_stats) do
    {
      '12345' => {
        'name' => 'Messi',
        'stats' => [
          {
            'key' => 'top_stats',
            'stats' => {
              'FotMob rating' => { 'stat' => { 'value' => 8.5 } },
              'Minutes played' => { 'stat' => { 'value' => 90 } },
              'Goals' => { 'stat' => { 'value' => 1 } },
              'Assists' => { 'stat' => { 'value' => 0 } },
              'Goals conceded' => { 'stat' => { 'value' => 0 } },
              'Penalty goals conceded' => { 'stat' => { 'value' => 0 } },
              'Own goal' => { 'stat' => { 'value' => 0 } },
              'Conceded penalty' => { 'stat' => { 'value' => 0 } },
              'Penalties won' => { 'stat' => { 'value' => 0 } },
              'Saved penalties' => { 'stat' => { 'value' => 0 } },
              'Missed penalty' => { 'stat' => { 'value' => 0 } },
              'Saves' => { 'stat' => { 'value' => 0 } }
            }
          }
        ]
      }
    }
  end

  describe '#call' do
    context 'when playerStats is nil' do
      let(:match_data) do
        { 'playerStats' => nil, 'matchFacts' => { 'events' => { 'events' => [] } } }
      end

      it { is_expected.to eq({}) }
    end

    context 'with valid player stats' do
      it 'keys the result by integer fotmob_id' do
        expect(result.keys).to contain_exactly(12_345)
      end

      it 'extracts rating' do
        expect(result[12_345][:rating]).to eq(8.5)
      end

      it 'extracts played_minutes' do
        expect(result[12_345][:played_minutes]).to eq(90)
      end

      it 'extracts goals' do
        expect(result[12_345][:goals]).to eq(1)
      end

      it 'stores fotmob_id' do
        expect(result[12_345][:fotmob_id]).to eq(12_345)
      end

      it 'stores normalized fotmob_name' do
        expect(result[12_345][:fotmob_name]).to eq('messi')
      end
    end

    context 'when a stat key is missing' do
      let(:player_stats) do
        {
          '99' => {
            'name' => 'Sub',
            'stats' => [
              {
                'key' => 'top_stats',
                'stats' => {
                  'FotMob rating' => { 'stat' => { 'value' => 6.0 } },
                  'Minutes played' => { 'stat' => { 'value' => 45 } }
                }
              }
            ]
          }
        }
      end

      it 'defaults goals to 0' do
        expect(result[99][:goals]).to eq(0)
      end

      it 'defaults saves to 0' do
        expect(result[99][:saves]).to eq(0)
      end
    end

    context 'when player stats array is empty' do
      let(:player_stats) do
        { '42' => { 'name' => 'Reserve', 'stats' => [] } }
      end

      it 'returns only fotmob_id and fotmob_name' do
        expect(result[42]).to eq({ fotmob_id: 42, fotmob_name: 'reserve' })
      end
    end

    context 'with a yellow card event' do
      let(:events) do
        [{ 'type' => 'Card', 'card' => 'Yellow', 'player' => { 'id' => 12_345 } }]
      end

      it 'sets yellow_card to 1' do
        expect(result[12_345][:yellow_card]).to eq(1)
      end
    end

    context 'with a red card event' do
      let(:events) do
        [{ 'type' => 'Card', 'card' => 'Red', 'player' => { 'id' => 12_345 } }]
      end

      it 'sets red_card to 1' do
        expect(result[12_345][:red_card]).to eq(1)
      end
    end

    context 'with a YellowRed card event' do
      let(:events) do
        [{ 'type' => 'Card', 'card' => 'YellowRed', 'player' => { 'id' => 12_345 } }]
      end

      it 'sets red_card to 1' do
        expect(result[12_345][:red_card]).to eq(1)
      end

      it 'clears yellow_card' do
        expect(result[12_345][:yellow_card]).to eq(0)
      end
    end

    context 'with a penalty goal event' do
      let(:events) do
        [{ 'type' => 'Goal', 'goalDescriptionKey' => 'penalty', 'player' => { 'id' => 12_345 } }]
      end

      it 'decrements goals by 1' do
        expect(result[12_345][:goals]).to eq(0)
      end

      it 'increments scored_penalty by 1' do
        expect(result[12_345][:scored_penalty]).to eq(1)
      end
    end

    context 'with multiple penalty goals for the same player' do
      let(:events) do
        [
          { 'type' => 'Goal', 'goalDescriptionKey' => 'penalty', 'player' => { 'id' => 12_345 } },
          { 'type' => 'Goal', 'goalDescriptionKey' => 'penalty', 'player' => { 'id' => 12_345 } }
        ]
      end

      let(:player_stats) do
        {
          '12345' => {
            'name' => 'Messi',
            'stats' => [
              {
                'key' => 'top_stats',
                'stats' => {
                  'FotMob rating' => { 'stat' => { 'value' => 8.5 } },
                  'Minutes played' => { 'stat' => { 'value' => 90 } },
                  'Goals' => { 'stat' => { 'value' => 2 } }
                }
              }
            ]
          }
        }
      end

      it 'accumulates scored_penalty' do
        expect(result[12_345][:scored_penalty]).to eq(2)
      end

      it 'reduces goals to zero' do
        expect(result[12_345][:goals]).to eq(0)
      end
    end

    context 'with an event for an unknown player' do
      let(:events) do
        [{ 'type' => 'Card', 'card' => 'Yellow', 'player' => { 'id' => 99_999 } }]
      end

      it 'does not raise' do
        expect { result }.not_to raise_error
      end
    end

    context 'with a non-card, non-penalty goal event' do
      let(:events) do
        [{ 'type' => 'Goal', 'goalDescriptionKey' => 'regular', 'player' => { 'id' => 12_345 } }]
      end

      it 'does not modify goals' do
        expect(result[12_345][:goals]).to eq(1)
      end

      it 'does not set scored_penalty' do
        expect(result[12_345][:scored_penalty]).to be_nil
      end
    end
  end
end
