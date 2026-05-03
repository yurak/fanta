require 'rails_helper'

RSpec.describe NationalTeamSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:national_team))

      expect(serializer.serializable_hash.keys).to match_array(%i[id code color kit_path name profile_kit_path status tournament_id])
    end
  end
end
