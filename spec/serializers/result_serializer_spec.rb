require 'rails_helper'

RSpec.describe ResultSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:result, history: '[]'))

      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end
  end

  def expected_keys
    %i[
      id best_lineup draws form goals_difference history league_id loses matches_played
      missed_goals next_opponent_id penalty_points points scored_goals team total_score wins
    ]
  end
end
