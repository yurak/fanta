RSpec.describe ApplicationRecord do
  describe '.abstract_class' do
    it 'is abstract' do
      expect(described_class.abstract_class).to be(true)
    end
  end

  describe 'URL_REGEXP' do
    let(:http_url) { 'http://example.com/path' }
    let(:https_url) { 'https://example.com/path' }
    let(:relative_path) { 'bad/path/to/file' }

    it 'matches http urls' do
      expect(http_url).to match(described_class::URL_REGEXP)
    end

    it 'matches https urls' do
      expect(https_url).to match(described_class::URL_REGEXP)
    end

    it 'does not match relative paths' do
      expect(relative_path).not_to match(described_class::URL_REGEXP)
    end
  end
end
