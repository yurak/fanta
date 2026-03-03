RSpec.describe TelegramBot::Auction::AuctionNotifier do
  describe '#call' do
    subject(:service_call) { described_class.new(auction).call }

    let(:auction) { create(:auction) }

    context 'when auction is nil' do
      let(:auction) { nil }

      it 'returns false' do
        expect(service_call).to be(false)
      end

      it 'does not call sender' do
        allow(TelegramBot::Sender).to receive(:call)

        service_call

        expect(TelegramBot::Sender).not_to have_received(:call)
      end
    end

    context 'when auction league has no teams' do
      it 'returns false' do
        expect(service_call).to be(false)
      end
    end

    context 'when auction league has teams' do
      let(:tournament) { create(:tournament, code: 'epl', icon: '🏆') }
      let(:league) { create(:league, tournament: tournament) }
      let(:auction) { create(:auction, league: league) }
      let(:ua_user) { create(:user, locale: :ua) }
      let!(:ua_team) { create(:team, league: league, user: ua_user, human_name: 'UA Team') }
      let!(:anon_team) { create(:team, league: league, user: nil, human_name: 'Anon Team') }

      before do
        allow(I18n).to receive(:t) do |_key, **opts|
          "message-#{opts[:team_name]}-#{opts[:locale]}"
        end
        allow(TelegramBot::Sender).to receive(:call)
      end

      it 'returns true' do
        expect(service_call).to be(true)
      end

      it 'calls sender for team with user' do
        service_call

        expect(TelegramBot::Sender).to have_received(:call).with(ua_user, 'message-UA Team-ua')
      end

      it 'calls sender for team without user' do
        service_call

        expect(TelegramBot::Sender).to have_received(:call).with(nil, 'message-Anon Team-en')
      end

      it 'builds ua locale translation for team user' do
        service_call

        expect_translation_call(team_name: ua_team.human_name, locale: :ua, tournament: tournament)
      end

      it 'builds english locale translation for team without user' do
        service_call

        expect_translation_call(team_name: anon_team.human_name, locale: :en, tournament: tournament)
      end

      it 'returns true even when sender returns false' do
        allow(TelegramBot::Sender).to receive(:call).and_return(false)

        expect(service_call).to be(true)
      end
    end

    def expect_translation_call(team_name:, locale:, tournament:)
      expect(I18n).to have_received(:t).with(
        'telegram.notifier.auction.default',
        locale: locale,
        icon: tournament.icon,
        team_name: team_name,
        code: tournament.code
      )
    end
  end
end
