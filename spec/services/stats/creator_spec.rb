RSpec.describe Stats::Creator do
  describe '#call' do
    subject(:creator) { described_class.new }

    let(:tournament) { create(:tournament, :with_38_rounds) }
    let!(:club) { create(:club, :with_players_by_pos, tournament: tournament) }
    let(:player) { club.players.last }

    context 'without played matches' do
      it { expect(creator.call).to be(true) }

      it 'creates a zeroed player stats record' do
        creator.call

        expect(player.player_season_stats.find_by(club: player.club)).not_to be_nil
      end

      it 'sets played_matches to 0' do
        creator.call

        expect(player.player_season_stats.find_by(club: player.club).played_matches).to eq(0)
      end

      it 'does not overwrite an existing stats record' do
        creator.call
        creator.call

        expect(player.player_season_stats.count).to eq(1)
      end

      context 'when club has no tournament' do
        let(:club_no_tournament) { create(:club, tournament: nil) }
        let!(:orphan_player) { create(:player, club: club_no_tournament) }

        it 'does not raise' do
          expect { creator.call }.not_to raise_error
        end

        it 'skips the player without creating a stats record' do
          creator.call

          expect(orphan_player.player_season_stats.count).to eq(0)
        end
      end
    end

    context 'with played matches' do
      before do
        create(:round_player, player: player, tournament_round: tournament.tournament_rounds.first, score: 6.6, yellow_card: true)
        create(:round_player, player: player, tournament_round: tournament.tournament_rounds[13], score: 8.3, goals: 2, yellow_card: true)
        create(:round_player, player: player, tournament_round: tournament.tournament_rounds[15], score: 7.4, goals: 1)
      end

      it { expect(creator.call).to be(true) }

      it 'creates player stats record' do
        creator.call

        expect(player.player_season_stats.count).to eq(1)
      end

      it 'saves player score' do
        creator.call

        expect(player.player_season_stats.last.score).to eq(7.43)
      end

      it 'saves player goals' do
        creator.call

        expect(player.player_season_stats.last.goals).to eq(3)
      end

      it 'saves player cards' do
        creator.call

        expect(player.player_season_stats.last.yellow_card).to eq(2)
      end
    end

    context 'with played matches for 2 clubs' do
      let!(:club_previous) { create(:club, tournament: tournament) }

      before do
        create(:round_player, player: player, club: club_previous, tournament_round: tournament.tournament_rounds.first, score: 5.5,
                              yellow_card: true)
        create(:round_player, player: player, club: club_previous, tournament_round: tournament.tournament_rounds[13], score: 8.3, goals: 2)
        create(:round_player, player: player, tournament_round: tournament.tournament_rounds[13], score: 7.5, yellow_card: true)
        create(:round_player, player: player, tournament_round: tournament.tournament_rounds[13], score: 8.3, goals: 2, yellow_card: true)
        create(:round_player, player: player, tournament_round: tournament.tournament_rounds[15], score: 7.4, goals: 1)
      end

      it { expect(creator.call).to be(true) }

      it 'creates player stats record for each club' do
        creator.call

        expect(player.player_season_stats.count).to eq(2)
      end

      it 'saves player score for first club' do
        creator.call

        expect(player.player_season_stats.first.score).to eq(6.9)
      end

      it 'saves player score for last club' do
        creator.call

        expect(player.player_season_stats.last.score).to eq(7.73)
      end

      it 'saves player goals for first club' do
        creator.call

        expect(player.player_season_stats.first.goals).to eq(2)
      end

      it 'saves player goals for last club' do
        creator.call

        expect(player.player_season_stats.last.goals).to eq(3)
      end

      it 'saves player cards for first club' do
        creator.call

        expect(player.player_season_stats.first.yellow_card).to eq(1)
      end

      it 'saves player cards for last club' do
        creator.call

        expect(player.player_season_stats.last.yellow_card).to eq(2)
      end
    end
  end
end
