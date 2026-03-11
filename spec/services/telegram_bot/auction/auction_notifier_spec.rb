RSpec.describe TelegramBot::Auction::AuctionNotifier do
  describe '#call' do
    subject(:service_call) { described_class.new(notification).call }

    let(:tournament) { create(:tournament, code: 'epl', icon: '🏆') }
    let(:league) { create(:league, tournament: tournament) }
    let(:auction) { create(:auction, league: league) }
    let(:user) { create(:user, locale: :ua) }
    let(:team) { create(:team, league: league, user: user, human_name: 'UA Team') }
    let(:notification) { create(:notification, notifiable: auction, team: team, kind: :auction_sales_open) }

    context 'when notifiable is nil' do
      let(:notification) { instance_double(Notification, notifiable: nil, team: team) }

      it 'returns false' do
        expect(service_call).to be(false)
      end

      it 'does not call sender' do
        allow(TelegramBot::Sender).to receive(:call)

        service_call

        expect(TelegramBot::Sender).not_to have_received(:call)
      end
    end

    context 'when team has no user' do
      let(:team) { create(:team, league: league, user: nil) }

      it 'returns false' do
        expect(service_call).to be(false)
      end

      it 'does not call sender' do
        allow(TelegramBot::Sender).to receive(:call)

        service_call

        expect(TelegramBot::Sender).not_to have_received(:call)
      end
    end

    context 'when team has a user' do
      before do
        allow(I18n).to receive(:t) do |_key, **opts|
          "message-#{opts[:team_name]}-#{opts[:locale]}"
        end
        allow(TelegramBot::Sender).to receive(:call)
      end

      it 'returns true' do
        expect(service_call).to be(true)
      end

      it 'calls sender with user and message' do
        service_call

        expect(TelegramBot::Sender).to have_received(:call).with(user, 'message-UA Team-ua')
      end

      it 'builds translation with correct params' do
        service_call

        expect(I18n).to have_received(:t).with('telegram.notifier.auction.default',
                                               locale: :ua, icon: tournament.icon,
                                               team_name: team.human_name, code: tournament.code)
      end

      it 'returns true even when sender returns false' do
        allow(TelegramBot::Sender).to receive(:call).and_return(false)

        expect(service_call).to be(true)
      end
    end
  end
end
