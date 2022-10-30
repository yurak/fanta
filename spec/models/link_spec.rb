RSpec.describe Link do
  describe 'Associations' do
    it { is_expected.to belong_to(:tournament) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :url }

    it { is_expected.not_to allow_value('bad/path/to/file').for(:url) }
    it { is_expected.to allow_value('https://example.com/path/to/file').for(:url) }
  end
end
