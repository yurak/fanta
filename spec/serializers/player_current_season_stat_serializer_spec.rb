require 'rails_helper'

RSpec.describe PlayerCurrentSeasonStatSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(stubbed_player, matches: [])

      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end
  end

  def stubbed_player
    player = create(:player)
    allow(player).to receive_messages(
      season_bonus_count: 0,
      season_average_score: 0,
      season_cards_count: 0,
      season_scores_count: 0,
      season_average_result_score: 0
    )
    player
  end

  def expected_keys
    %i[
      assists base_score caught_penalty cleansheet conceded_penalty failed_penalty goals missed_goals missed_penalty own_goals penalties_won
      played_matches played_minutes red_card saves scored_penalty total_score yellow_card
    ]
  end
end
