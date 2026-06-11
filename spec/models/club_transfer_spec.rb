RSpec.describe ClubTransfer do
  describe 'associations' do
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:old_club).class_name('Club').optional }
    it { is_expected.to belong_to(:new_club).class_name('Club').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:start_date) }

    it { is_expected.to validate_presence_of(:new_club_name) }

    context 'when new_club is set' do
      subject { build(:club_transfer, new_club: create(:club), new_club_name: nil) }

      it { is_expected.to validate_presence_of(:new_club_name) }
    end
  end

  describe 'scopes' do
    describe '.recent' do
      let(:player) { create(:player) }
      let(:old_club) { create(:club) }
      let(:interim_club) { create(:club) }
      let(:latest_club) { create(:club) }
      let!(:older) { create(:club_transfer, player: player, old_club: old_club, new_club: interim_club, start_date: 1.month.ago) }
      let!(:newer) { create(:club_transfer, player: player, old_club: interim_club, new_club: latest_club, start_date: Time.zone.today) }

      it 'orders by start_date descending' do
        expect(described_class.recent.to_a).to eq([newer, older])
      end
    end
  end
end
