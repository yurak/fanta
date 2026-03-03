require 'rails_helper'

RSpec.describe SeasonSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:season))

      expect(serializer.serializable_hash.keys).to match_array(%i[id end_year start_year])
    end
  end
end
