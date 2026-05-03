RSpec.describe TelegramBot::Auction::SalesOpenNotifier do
  describe '#call' do
    subject(:service_call) { described_class.new(notification).call }

    let(:tournament) { create(:tournament, code: 'epl', icon: '🏆') }
    let(:league) { create(:league, tournament: tournament) }
    let(:auction) { create(:auction, league: league) }
    let(:user) { create(:user, locale: :ua, time_zone: 'Kyiv') }
    let(:team) { create(:team, league: league, user: user, human_name: 'UA Team') }
    let(:notification) { create(:notification, notifiable: auction, team: team, kind: :auction_sales_open) }

    context 'when team has no user' do
      let(:team) { create(:team, league: league, user: nil) }

      it { expect(service_call).to be(false) }
    end

    context 'when team has a user' do
      before do
        create(:player_team, team: team)
        allow(TelegramBot::Sender).to receive(:call).and_return(true)
        allow(I18n).to receive(:t).and_return('message')
      end

      it { expect(service_call).to be(true) }

      it 'calls sender with user' do
        service_call

        expect(TelegramBot::Sender).to have_received(:call).with(user, 'message')
      end

      it 'uses sales_open translation key' do
        service_call

        expect(I18n).to have_received(:t).with('telegram.notifier.auction.sales_open', hash_including(locale: :ua))
      end
    end
  end
end
