require 'rails_helper'

RSpec.describe PlayerLineupSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:player))

      expect(serializer.serializable_hash.keys).to match_array(
        %i[id avatar_path club_code club_color club_logo club_name first_name kit_path leagues name national_kit_path national_team_code
           national_team_color national_team_name position_arr position_classic_arr stats_price]
      )
    end
  end
end
