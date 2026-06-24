RSpec.describe UserLogo do
  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:url) }
  end

  describe 'enum status' do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, approved: 1, rejected: 2) }
  end

  describe 'soft delete' do
    subject(:logo) { create(:user_logo) }

    it { expect(described_class.kept).to include(logo) }

    context 'when discarded' do
      before { logo.discard }

      it { expect(logo.discarded?).to be(true) }
      it { expect(described_class.kept).not_to include(logo) }
      it { expect(described_class.discarded).to include(logo) }
    end
  end

  describe '#in_use?' do
    subject(:logo) { create(:user_logo, user: user) }

    let(:user) { create(:user) }

    context 'when a team of the owner uses this logo url' do
      before { create(:team, :with_user, user: user, logo_url: logo.url) }

      it { expect(logo.in_use?).to be(true) }
    end

    context 'when no team uses this logo url' do
      it { expect(logo.in_use?).to be(false) }
    end
  end

  describe '#discard when the logo is in use' do
    subject(:logo) { create(:user_logo, user: user) }

    let(:user) { create(:user) }

    before { create(:team, :with_user, user: user, logo_url: logo.url) }

    it 'does not soft-delete the logo' do
      logo.discard
      expect(logo.reload.discarded?).to be(false)
    end
  end
end
