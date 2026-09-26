RSpec.describe Scores::Injectors::SofascoreIncidents do
  subject(:timeline) { described_class.new(incidents_json) }

  let(:incidents_json) { { 'incidents' => incidents }.to_json }
  let(:incidents) { [] }

  describe 'a blob we cannot read' do
    context 'with nil' do
      subject(:timeline) { described_class.new(nil) }

      it { expect(timeline.cards).to eq({}) }
      it { expect(timeline.substitutions).to eq({}) }
    end

    context 'with text that is not JSON' do
      subject(:timeline) { described_class.new('<html>502</html>') }

      it { expect(timeline.penalty_goals).to eq({}) }
    end

    context 'with JSON that carries no incidents key' do
      subject(:timeline) { described_class.new({ 'event' => {} }.to_json) }

      it { expect(timeline.goal_minutes_conceded_by(home: true)).to eq([]) }
    end
  end

  describe '#cards' do
    context 'with a booking' do
      let(:incidents) do
        [{ 'incidentType' => 'card', 'incidentClass' => 'yellow', 'time' => 30, 'player' => { 'id' => 1 } }]
      end

      it { expect(timeline.cards[1]).to eq(yellow_card: true, red_card: false) }
    end

    # A second yellow is a sending off, not a booking on top of one.
    context 'with a second yellow' do
      let(:incidents) do
        [{ 'incidentType' => 'card', 'incidentClass' => 'yellow', 'time' => 30, 'player' => { 'id' => 1 } },
         { 'incidentType' => 'card', 'incidentClass' => 'yellowRed', 'time' => 70, 'player' => { 'id' => 1 } }]
      end

      it { expect(timeline.cards[1]).to eq(yellow_card: false, red_card: true) }
    end

    # The feed does not promise chronological order, so a booking listed after the sending off must
    # not downgrade it back to a yellow.
    context 'with the booking listed after the sending off' do
      let(:incidents) do
        [{ 'incidentType' => 'card', 'incidentClass' => 'yellowRed', 'time' => 70, 'player' => { 'id' => 1 } },
         { 'incidentType' => 'card', 'incidentClass' => 'yellow', 'time' => 30, 'player' => { 'id' => 1 } }]
      end

      it { expect(timeline.cards[1]).to eq(yellow_card: false, red_card: true) }
    end

    context 'with a card the referee rescinded' do
      let(:incidents) do
        [{ 'incidentType' => 'card', 'incidentClass' => 'red', 'time' => 30,
           'rescinded' => true, 'player' => { 'id' => 1 } }]
      end

      it { expect(timeline.cards).to eq({}) }
    end

    context 'with a card carrying no player' do
      let(:incidents) { [{ 'incidentType' => 'card', 'incidentClass' => 'red', 'time' => 30 }] }

      it 'ignores it, rather than indexing the whole match under nil' do
        expect(timeline.cards).to eq({})
      end
    end
  end

  describe '#red_card_minutes' do
    let(:incidents) do
      [{ 'incidentType' => 'card', 'incidentClass' => 'yellow', 'time' => 30, 'player' => { 'id' => 1 } },
       { 'incidentType' => 'card', 'incidentClass' => 'red', 'time' => 45, 'addedTime' => 2,
         'player' => { 'id' => 2 } }]
    end

    it 'counts stoppage time into the minute' do
      expect(timeline.red_card_minutes[2]).to eq(47)
    end

    it 'leaves out a player who was only booked' do
      expect(timeline.red_card_minutes).not_to have_key(1)
    end
  end

  describe '#substitutions' do
    let(:incidents) do
      [{ 'incidentType' => 'substitution', 'time' => 62,
         'playerIn' => { 'id' => 1 }, 'playerOut' => { 'id' => 2 } }]
    end

    it 'records when the substitute came on' do
      expect(timeline.substitutions[1]).to eq(on_minute: 62)
    end

    it 'records when the player he replaced went off' do
      expect(timeline.substitutions[2]).to eq(off_minute: 62)
    end

    context 'when the same player comes on and is then taken off again' do
      let(:incidents) do
        [{ 'incidentType' => 'substitution', 'time' => 30, 'playerIn' => { 'id' => 1 }, 'playerOut' => { 'id' => 2 } },
         { 'incidentType' => 'substitution', 'time' => 80, 'playerIn' => { 'id' => 3 }, 'playerOut' => { 'id' => 1 } }]
      end

      it 'keeps both ends of his spell' do
        expect(timeline.substitutions[1]).to eq(on_minute: 30, off_minute: 80)
      end
    end
  end

  describe '#penalty_goals' do
    let(:incidents) do
      [{ 'incidentType' => 'goal', 'incidentClass' => 'penalty', 'time' => 20, 'player' => { 'id' => 1 } },
       { 'incidentType' => 'goal', 'incidentClass' => 'penalty', 'time' => 60, 'player' => { 'id' => 1 } },
       { 'incidentType' => 'goal', 'incidentClass' => 'regular', 'time' => 70, 'player' => { 'id' => 1 } }]
    end

    it 'counts only the penalties' do
      expect(timeline.penalty_goals[1]).to eq(2)
    end

    it 'answers nought for a player who scored none' do
      expect(timeline.penalty_goals[99]).to eq(0)
    end
  end

  describe 'goals conceded' do
    let(:incidents) do
      [{ 'incidentType' => 'goal', 'incidentClass' => 'regular', 'isHome' => true, 'time' => 10 },
       { 'incidentType' => 'goal', 'incidentClass' => 'penalty', 'isHome' => false, 'time' => 55,
         'player' => { 'id' => 7 } }]
    end

    it 'gives the home side the minutes the visitors scored' do
      expect(timeline.goal_minutes_conceded_by(home: true)).to eq([55])
    end

    it 'gives the visitors the minutes the home side scored' do
      expect(timeline.goal_minutes_conceded_by(home: false)).to eq([10])
    end

    it 'separates out the penalties conceded' do
      expect(timeline.penalty_minutes_conceded_by(home: true)).to eq([55])
    end

    it 'leaves the other side no penalties conceded' do
      expect(timeline.penalty_minutes_conceded_by(home: false)).to eq([])
    end
  end
end
