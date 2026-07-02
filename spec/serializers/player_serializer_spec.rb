require 'rails_helper'

RSpec.describe PlayerSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:player))

      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end
  end

  def expected_keys
    %i[
      id appearances appearances_max avatar_path average_base_score average_price average_total_score club
      first_name league_price league_team_logo name position_classic_arr position_ital_arr teams_count
      teams_count_max age birth_date country height leagues national_team number profile_avatar_path
      stats_price team_ids tm_price tm_url club_transfers nationality profile_kit_path season_score teams
    ]
  end
end
