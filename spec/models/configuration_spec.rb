require 'cancan/matchers'

RSpec.describe Configuration do
  describe '.sofa_server_url' do
    context 'when sofascore configuration does not exist' do
      it 'returns nil' do
        expect(described_class.sofa_server_url).to be_nil
      end
    end

    context 'when sofascore configuration exists' do
      let!(:config) { create(:configuration, provider: 'sofascore', payload: 'test') }

      it 'returns nil' do
        expect(described_class.sofa_server_url).to eq(config.payload)
      end
    end
  end
end
