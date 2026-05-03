require 'rails_helper'

RSpec.describe ClubSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:club))

      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end
  end

  def expected_keys
    %i[id code color kit_path logo_path name profile_kit_path status tm_url tournament_id]
  end
end
