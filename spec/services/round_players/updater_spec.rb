RSpec.describe RoundPlayers::Updater do
  describe '#call' do
    subject(:updater) { described_class.new(tournament_round) }

    let(:tournament_round) { create(:tournament_round, :with_finished_matches) }

    context 'with blank tournament_round' do
      let(:tournament_round) { nil }

      it { expect(updater.call).to eq(false) }
    end

    context 'with not finished tournament_round' do
      let(:tournament_round) { create(:tournament_round) }

      it { expect(updater.call).to eq(false) }
    end

    context 'when tournament_round without round_players' do
      it { expect(updater.call).to eq(false) }
    end

    context 'when tournament_round with round_players without scores' do
      let!(:round_player) { create(:round_player, tournament_round: tournament_round) }

      before do
        updater.call
      end

      it 'does not update round_player final_score' do
        expect(round_player.reload.final_score).to eq(0)
      end
    end

    context 'when tournament_round with round_players with scores' do
      let!(:round_player) { create(:round_player, :with_score_seven, assists: 1, tournament_round: tournament_round) }

      before do
        updater.call
      end

      it 'updates round_player final_score' do
        expect(round_player.reload.final_score).to eq(8)
      end
    end
  end
end
