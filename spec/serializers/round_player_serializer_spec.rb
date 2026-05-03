require 'rails_helper'

RSpec.describe RoundPlayerSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:round_player))

      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end
  end

  def expected_keys
    %i[
      id assists base_score caught_penalty cleansheet club_id conceded_penalty failed_penalty goals
      missed_penalty missed_goals own_goals penalties_won played_minutes player_id red_card saves
      scored_penalty total_score tournament_round_id tournament_round_number yellow_card
    ]
  end
end
