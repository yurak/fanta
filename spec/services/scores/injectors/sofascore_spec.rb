RSpec.describe Scores::Injectors::Sofascore do
  describe '#call' do
    subject(:injector) { described_class.new(tournament_round) }

    let(:tournament_round) { create(:tournament_round) }
    let(:base_data) { '{"event":{}}' }
    let(:lineups_data) { '{"home":{}}' }

    before { allow(Scores::Injectors::SofascoreMatch).to receive(:call) }

    context 'when match has both base_data and lineups_data' do
      let!(:match) do
        create(:tournament_match, tournament_round: tournament_round,
                                  base_data: base_data, lineups_data: lineups_data)
      end

      it 'delegates to SofascoreMatch' do
        injector.call
        expect(Scores::Injectors::SofascoreMatch).to have_received(:call).with(match)
      end
    end

    context 'when match has blank base_data' do
      before { create(:tournament_match, tournament_round: tournament_round, base_data: nil, lineups_data: lineups_data) }

      it 'does not call SofascoreMatch' do
        injector.call
        expect(Scores::Injectors::SofascoreMatch).not_to have_received(:call)
      end
    end

    context 'when match has blank lineups_data' do
      before { create(:tournament_match, tournament_round: tournament_round, base_data: base_data, lineups_data: nil) }

      it 'does not call SofascoreMatch' do
        injector.call
        expect(Scores::Injectors::SofascoreMatch).not_to have_received(:call)
      end
    end

    context 'when there are no matches' do
      it 'does not call SofascoreMatch' do
        injector.call
        expect(Scores::Injectors::SofascoreMatch).not_to have_received(:call)
      end
    end

    context 'with mixed matches' do
      let!(:valid_match) do
        create(:tournament_match, tournament_round: tournament_round,
                                  base_data: base_data, lineups_data: lineups_data)
      end

      before do
        create(:tournament_match, tournament_round: tournament_round, base_data: nil, lineups_data: lineups_data)
        create(:tournament_match, tournament_round: tournament_round, base_data: base_data, lineups_data: nil)
      end

      it 'only processes the valid match' do
        injector.call
        expect(Scores::Injectors::SofascoreMatch).to have_received(:call).once.with(valid_match)
      end
    end
  end
end
