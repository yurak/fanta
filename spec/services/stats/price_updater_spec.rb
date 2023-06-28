RSpec.describe Stats::PriceUpdater do
  describe '#call' do
    subject(:updater) { described_class.new(tournament) }

    let(:tournament) { create(:tournament) }
    let(:season) { create(:season) }

    context 'without tournament' do
      let(:tournament) { nil }

      it { expect(updater.call).to be(false) }
    end

    context 'with tournament' do
      context 'without stats' do
        it { expect(updater.call).to be(true) }
      end

      context 'with stats' do
        before do
          (5..10).each do |score|
            create(:player_season_stat, tournament: tournament, season: season, played_matches: 15, final_score: score, position1: 'Dc')
          end
          create(:player_season_stat, tournament: tournament, season: season, played_matches: 15, final_score: 8.6, position1: 'Por')
        end

        it { expect(updater.call).to be(true) }

        it 'sets price for top-5 by position' do
          updater.call

          expect(tournament.player_season_stats.where('position_price > ?', 1).count).to eq(6)
        end
      end
    end
  end
end
