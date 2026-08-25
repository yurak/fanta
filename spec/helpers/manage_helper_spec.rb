RSpec.describe ManageHelper do
  before { allow(helper).to receive(:current_user).and_return(build(:user, time_zone: 'Kyiv')) }

  # 20:30 UTC on Dec 22 is 22:30 in Kyiv (UTC+2 in winter)
  let(:winter_evening) { Time.utc(2026, 12, 22, 20, 30) }

  describe '#tour_dashboard_deadline' do
    it 'formats the deadline in the admin time zone' do
      expect(helper.tour_dashboard_deadline(winter_evening)).to eq('22:30 22/12/26')
    end

    it 'returns a placeholder when the deadline is missing' do
      expect(helper.tour_dashboard_deadline(nil)).to eq('--:--')
    end
  end

  describe '#tour_dashboard_moderated_at' do
    it 'adds 18 hours and formats it in the admin time zone' do
      # 20:30 UTC Dec 22 + 18h = 14:30 UTC Dec 23 => 16:30 Kyiv Dec 23
      expect(helper.tour_dashboard_moderated_at(winter_evening)).to eq('16:30 23/12/26')
    end

    it 'returns nil when not moderated yet' do
      expect(helper.tour_dashboard_moderated_at(nil)).to be_nil
    end
  end
end
