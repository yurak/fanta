require 'rails_helper'

RSpec.describe PlayerStatsSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:player))

      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end
  end

  def expected_keys
    %i[
      id current_season_stat current_season_stat_eurocup current_season_stat_national
      round_stats round_stats_eurocup round_stats_national season_stats
    ]
  end
end
