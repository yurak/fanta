RSpec.describe ArticleTag do
  describe 'Associations' do
    it { is_expected.to belong_to(:tournament).optional }
    it { is_expected.to have_many(:articles).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }

    it { is_expected.to validate_presence_of :color }
    it { is_expected.to validate_length_of(:color).is_equal_to(6) }

    it { is_expected.to define_enum_for(:status).with_values(%i[published hidden]) }
  end
end
