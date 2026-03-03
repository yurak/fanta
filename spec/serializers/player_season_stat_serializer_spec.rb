require 'rails_helper'

RSpec.describe PlayerSeasonStatSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:player_season_stat))

      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end
  end

  def expected_keys
    %i[
      id assists base_score caught_penalty cleansheet club_id conceded_penalty failed_penalty goals
      missed_goals missed_penalty own_goals penalties_won played_minutes played_matches player_id
      position_price position_classic_arr position_ital_arr red_card saves scored_penalty season_id
      total_score tournament_id yellow_card
    ]
  end
end
