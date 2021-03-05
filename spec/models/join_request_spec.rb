RSpec.describe JoinRequest, type: :model do
  describe 'Validations' do
    it { is_expected.to validate_presence_of :username }
    it { is_expected.to validate_presence_of :contact }
    it { is_expected.to validate_presence_of :email }

    it { is_expected.not_to allow_value('bad_email').for(:email) }
    it { is_expected.to allow_value('good@email.com').for(:email) }

    it { is_expected.to define_enum_for(:status).with_values(%i[initial processed archived]) }
  end
end
