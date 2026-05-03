RSpec.describe Scores::Injectors::Fotmob do
  describe '#call' do
    subject(:injector) { described_class.new(tournament_round) }

    let(:tournament_round) { create(:tournament_round) }

    before { allow(Scores::Injectors::FotmobMatch).to receive(:call) }

    context 'when match has a page_url' do
      let!(:match) { create(:tournament_match, tournament_round: tournament_round, page_url: '/match/1') }

      it 'delegates to FotmobMatch' do
        injector.call
        expect(Scores::Injectors::FotmobMatch).to have_received(:call).with(match)
      end
    end

    context 'when match has a nil page_url' do
      before do
        nil_match = instance_double(TournamentMatch, page_url: nil)
        allow(tournament_round).to receive(:tournament_matches).and_return([nil_match])
      end

      it 'does not call FotmobMatch' do
        injector.call
        expect(Scores::Injectors::FotmobMatch).not_to have_received(:call)
      end
    end

    context 'when match has an empty page_url' do
      before { create(:tournament_match, tournament_round: tournament_round, page_url: '') }

      it 'does not call FotmobMatch' do
        injector.call
        expect(Scores::Injectors::FotmobMatch).not_to have_received(:call)
      end
    end

    context 'with multiple matches' do
      before do
        create(:tournament_match, tournament_round: tournament_round, page_url: '/match/1')
        create(:tournament_match, tournament_round: tournament_round, page_url: '/match/2')
        create(:tournament_match, tournament_round: tournament_round, page_url: '')
      end

      it 'calls FotmobMatch only for matches with a page_url' do
        injector.call
        expect(Scores::Injectors::FotmobMatch).to have_received(:call).twice
      end
    end
  end
end
