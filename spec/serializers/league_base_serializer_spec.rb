require 'rails_helper'

RSpec.describe LeagueBaseSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:league))

      expected_keys = %i[id demo division division_id link name season_id status tournament_id results]
      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end

    it 'includes demo flag' do
      demo_league = create(:active_league, demo: true)
      serializer = described_class.new(demo_league)

      expect(serializer.serializable_hash[:demo]).to be(true)
    end
  end
end
