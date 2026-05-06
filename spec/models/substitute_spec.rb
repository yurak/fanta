RSpec.describe Substitute do
  subject(:substitute) { create(:substitute) }

  describe 'Associations' do
    it { is_expected.to belong_to(:main_mp).class_name('MatchPlayer') }
    it { is_expected.to belong_to(:reserve_mp).class_name('MatchPlayer') }
    it { is_expected.to belong_to(:in_rp).class_name('RoundPlayer') }
    it { is_expected.to belong_to(:out_rp).class_name('RoundPlayer') }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:subs_by).with_values(%i[manual autobot]) }
  end
end
