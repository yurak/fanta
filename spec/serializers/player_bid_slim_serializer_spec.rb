require 'rails_helper'

RSpec.describe PlayerBidSlimSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:player_bid))

      expect(serializer.serializable_hash.keys).to match_array(%i[id status price team])
    end
  end
end
