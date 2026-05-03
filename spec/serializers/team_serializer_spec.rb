require 'rails_helper'

RSpec.describe TeamSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:team))

      expect(serializer.serializable_hash.keys).to match_array(%i[id budget code human_name league_id logo_path players user_id])
    end
  end
end
