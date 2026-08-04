RSpec.describe AuctionBids::LineupGenerator do
  describe '#call' do
    subject(:generate) { described_class.call(auction_bid) }

    let(:tournament) { create(:tournament) }
    let(:club) { create(:club, tournament: tournament) }
    let(:team) { create(:team) }
    let(:auction_bid) { create(:auction_bid, team: team, auction_round: nil) }
    let(:filled_players) { auction_bid.player_bids.reload.filter_map(&:player) }

    def eligible_player(trait)
      player = create(:player, trait, club: club)
      create(:player_season_stat, player: player, club: club, tournament: tournament,
                                  season: Season.second_to_last, played_matches: 20)
      player
    end

    before do
      create(:season) # a newer season so the seeded one becomes the previous season
      create(:join, tournament: tournament, team: team, auction_bid: auction_bid)
      11.times { create(:player_bid, auction_bid: auction_bid, player: nil) }
    end

    context 'with enough eligible players across positions' do
      before do
        3.times { eligible_player(:with_pos_por) }
        %i[with_pos_dc with_pos_ds with_pos_dd with_pos_m with_pos_c].each { |t| 2.times { eligible_player(t) } }
      end

      it { is_expected.to be(true) }

      it 'fills every slot' do
        generate
        expect(auction_bid.player_bids.reload.where.not(player_id: nil).count).to eq(11)
      end

      it 'picks distinct players' do
        generate
        ids = auction_bid.player_bids.reload.pluck(:player_id)
        expect(ids).to eq(ids.uniq)
      end

      it 'includes a goalkeeper' do
        generate
        expect(filled_players.any? { |player| player.position_names.include?(Position::GOALKEEPER) }).to be(true)
      end
    end

    context 'when a player is below the appearance threshold' do
      let(:too_few) do
        player = create(:player, :with_pos_dc, club: club)
        create(:player_season_stat, player: player, club: club, tournament: tournament,
                                    season: Season.second_to_last, played_matches: 10)
        player
      end

      before do
        eligible_player(:with_pos_por)
        too_few
      end

      it 'never picks the low-appearance player' do
        generate
        expect(filled_players).not_to include(too_few)
      end
    end

    context 'when an eligible player belongs to another tournament' do
      let(:outsider) do
        other_club = create(:club, tournament: create(:tournament))
        player = create(:player, :with_pos_dc, club: other_club)
        create(:player_season_stat, player: player, club: other_club, tournament: other_club.tournament,
                                    season: Season.second_to_last, played_matches: 20)
        player
      end

      before do
        eligible_player(:with_pos_por)
        outsider
      end

      it 'never picks the out-of-tournament player' do
        generate
        expect(filled_players).not_to include(outsider)
      end
    end

    context 'when no player matches a slot position' do
      before { 3.times { eligible_player(:with_pos_por) } }

      it 'falls back to any eligible player for field slots' do
        generate
        # only goalkeepers are eligible: the GK slot plus two field slots fill via fallback
        expect(auction_bid.player_bids.reload.where.not(player_id: nil).count).to eq(3)
      end
    end

    context 'when the qualifying appearances were for a different club' do
      let(:wrong_club_player) do
        player = create(:player, :with_pos_dc, club: club)
        other_club = create(:club, tournament: tournament)
        create(:player_season_stat, player: player, club: other_club, tournament: tournament,
                                    season: Season.second_to_last, played_matches: 20)
        player
      end

      before do
        eligible_player(:with_pos_por)
        wrong_club_player
      end

      it 'never picks a player whose appearances were at a different club' do
        generate
        expect(filled_players).not_to include(wrong_club_player)
      end
    end

    context 'when a qualified player has a minimum price above 1' do
      let(:priced_player) do
        player = create(:player, :with_pos_por, club: club)
        create(:player_season_stat, player: player, club: club, tournament: tournament,
                                    season: Season.second_to_last, played_matches: 20, position_price: 15)
        player
      end

      before { priced_player }

      it 'sets the player_bid price to the player minimum (stats_price)' do
        generate
        player_bid = auction_bid.player_bids.reload.find_by(player_id: priced_player.id)
        expect(player_bid.price).to eq(15)
      end
    end

    context 'when no goalkeeper meets the appearance threshold' do
      let(:fallback_gk) { create(:player, :with_pos_por, club: club) }

      before do
        %i[with_pos_dc with_pos_m].each { |trait| 3.times { eligible_player(trait) } }
        fallback_gk
      end

      it 'fills the goalkeeper slot with any goalkeeper, not a field player' do
        generate
        expect(auction_bid.player_bids.reload.order(:id).first.player.position_names)
          .to include(Position::GOALKEEPER)
      end
    end
  end
end
