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

  def expected_keys
    %i[
      id current_season_stat current_season_stat_eurocup current_season_stat_national
      round_stats round_stats_eurocup round_stats_national season_stats
    ]
  end
end
