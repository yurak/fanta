require 'rails_helper'

RSpec.describe PlayerStatsSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:player))

      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end
  end

  describe '#round_stats' do
    let(:tournament) { create(:tournament, :with_clubs) }
    let(:player) { create(:player, club: tournament.clubs.first) }

    # Round players are created (and re-created) in an arbitrary order, and every score injection
    # rewrites the row, so the rounds must be sorted explicitly and not left in Postgres heap order.
    before do
      [3, 1, 2].each do |number|
        round = create(:tournament_round, number: number, tournament: tournament, season: Season.last)
        create(:round_player, player: player, tournament_round: round, in_squad: true)
      end
    end

    it 'returns the rounds newest first regardless of the creation order' do
      numbers = described_class.new(player).round_stats.map { |stat| stat.object.tournament_round.number }

      expect(numbers).to eq([3, 2, 1])
    end
  end

  # The picker used to be built from season_stats, and Stats::Creator writes none for a club without
  # a base tournament — so a player at a eurocup-only club could not open the running season at all.
  describe '#seasons' do
    subject(:seasons) { described_class.new(player).seasons.pluck(:id) }

    let(:ec_tournament) { create(:tournament) }
    let(:ec_club) { create(:club, tournament: nil, ec_tournament: ec_tournament) }
    let(:player) { create(:player, club: ec_club) }
    let(:current) { Season.last }

    it 'always offers the running season' do
      expect(seasons).to include(current.id)
    end

    it 'offers a season the player only has eurocup rounds in' do
      past = create(:season, start_year: 2090, end_year: 2091)
      round = create(:tournament_round, tournament: ec_tournament, season: past)
      create(:round_player, player: player, tournament_round: round)

      expect(seasons).to include(past.id)
    end

    it 'offers a season the player only has a season stat row in' do
      past = create(:season, start_year: 2092, end_year: 2093)
      create(:player_season_stat, player: player, season: past, club: ec_club)

      expect(seasons).to include(past.id)
    end

    it 'leaves out a season the player has nothing in' do
      empty = create(:season, start_year: 2094, end_year: 2095)
      create(:season, start_year: 2098, end_year: 2099) # so `empty` is not the running season

      expect(seasons).not_to include(empty.id)
    end

    it 'returns the newest season first' do
      past = create(:season, start_year: 2096, end_year: 2097)
      create(:player_season_stat, player: player, season: past, club: ec_club)

      expect(seasons.first).to eq(seasons.max)
    end
  end

  def expected_keys
    %i[
      id current_season_stat current_season_stat_eurocup current_season_stat_national
      round_stats round_stats_eurocup round_stats_national season_stats seasons
    ]
  end
end
