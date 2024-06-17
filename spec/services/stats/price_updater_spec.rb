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
            player = create(:player)
            create(:player_position, player: player, position: Position.find_by(name: 'Dc'))
            create(:player_season_stat, player: player, tournament: tournament, season: season,
                                        played_matches: 15, final_score: score, position1: 'Dc')
          end
          player_por = create(:player)
          create(:player_position, player: player_por, position: Position.find_by(name: 'Por'))
          create(:player_season_stat, player: player_por, tournament: tournament, season: season,
                                      played_matches: 15, final_score: 8.6, position1: 'Por')
          player_dd = create(:player)
          create(:player_position, player: player_dd, position: Position.find_by(name: 'Dd'))
          create(:player_season_stat, player: player_dd, tournament: tournament, season: season,
                                      played_matches: 15, final_score: 8.6, position1: 'Dc')
          player_dc = create(:player)
          create(:player_position, player: player_dc, position: Position.find_by(name: 'Dc'))
          create(:player_season_stat, player: player_dc, tournament: tournament, season: season,
                                      played_matches: 15, final_score: 8.6, position1: 'Dd')
        end

        it { expect(updater.call).to be(true) }

        it 'sets price for top-5 by position' do
          updater.call

          expect(tournament.player_season_stats.where('position_price > ?', 1).count).to eq(7)
        end
      end
    end
  end
end
