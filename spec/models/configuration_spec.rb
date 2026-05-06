require 'cancan/matchers'

RSpec.describe Configuration do
  describe 'Validations' do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_uniqueness_of(:provider) }
  end

  describe '.rollbar_token' do
    context 'when rollbar configuration does not exist' do
      it 'returns nil' do
        expect(described_class.rollbar_token).to be_nil
      end
    end

    context 'when rollbar configuration exists' do
      let!(:config) { create(:configuration, provider: 'rollbar', payload: 'rollbar-token') }

      it 'returns rollbar payload' do
        expect(described_class.rollbar_token).to eq(config.payload)
      end
    end
  end

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
