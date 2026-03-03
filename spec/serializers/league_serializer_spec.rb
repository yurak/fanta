require 'rails_helper'

RSpec.describe LeagueSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:league))

      expect(serializer.serializable_hash.keys).to match_array(
        %i[id auction_type cloning_status division division_id leader leader_logo link mantra_format max_avg_def_score min_avg_def_score
           name promotion relegation round season_id season_end_year season_start_year status teams_count tournament_id transfer_status]
      )
    end
  end
end
