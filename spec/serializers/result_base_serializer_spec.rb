require 'rails_helper'

RSpec.describe ResultBaseSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:result))

      expect(serializer.serializable_hash.keys).to match_array(%i[id points team_id team_name])
    end
  end
end
