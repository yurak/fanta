require 'rails_helper'

RSpec.describe LeagueBaseSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:league))

      expect(serializer.serializable_hash.keys).to match_array(%i[id division division_id link name season_id status tournament_id results])
    end
  end
end
