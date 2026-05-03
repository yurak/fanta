require 'rails_helper'

RSpec.describe TournamentSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:tournament), clubs: true)

      expect(serializer.serializable_hash.keys).to match_array(%i[id icon logo mantra_format name short_name clubs])
    end
  end
end
