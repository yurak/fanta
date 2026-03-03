require 'rails_helper'

RSpec.describe TeamSlimSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:team))

      expect(serializer.serializable_hash.keys).to match_array(%i[id human_name logo_path])
    end
  end
end
