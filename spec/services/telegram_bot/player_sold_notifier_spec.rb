RSpec.describe TelegramBot::PlayerSoldNotifier do
  describe '#call' do
    subject(:service_call) { described_class.new(player, team).call }

    let(:tournament) { create(:tournament, name: 'Premier League', code: 'epl', icon: '🏆') }
    let(:league) { create(:league, tournament: tournament) }
    let(:team) { create(:team, league: league, human_name: 'Dream Team') }
    let(:player) { create(:player, first_name: 'Lionel', name: 'Messi') }

    context 'when player is nil' do
      let(:player) { nil }

      it 'returns false' do
        expect(service_call).to be(false)
      end

      it 'does not call sender' do
        allow(TelegramBot::Sender).to receive(:call)

        service_call

        expect(TelegramBot::Sender).not_to have_received(:call)
      end
    end

    context 'when team is nil' do
      let(:team) { nil }

      it 'returns false' do
        expect(service_call).to be(false)
      end

      it 'does not call sender' do
        allow(TelegramBot::Sender).to receive(:call)

        service_call

        expect(TelegramBot::Sender).not_to have_received(:call)
      end
    end

    context 'when params are valid and team has no user' do
      let(:team) { create(:team, league: league, user: nil, human_name: 'Dream Team') }

      before do
        allow(I18n).to receive(:t).and_return('translated message')
        allow(TelegramBot::Sender).to receive(:call)
      end

      it 'uses english locale for translation' do
        service_call

        expect_translation_call(locale: :en)
      end

      it 'calls sender with team user and translated message' do
        service_call

        expect(TelegramBot::Sender).to have_received(:call).with(team.user, 'translated message')
      end

      it 'returns true' do
        expect(service_call).to be(true)
      end
    end

    context 'when params are valid and team user locale is ua' do
      let(:user) { create(:user, locale: :ua) }
      let(:team) { create(:team, league: league, user: user, human_name: 'Dream Team') }

      before do
        allow(I18n).to receive(:t).and_return('translated message')
        allow(TelegramBot::Sender).to receive(:call)
      end

      it 'uses user locale for translation' do
        service_call

        expect_translation_call(locale: :ua)
      end

      it 'returns true even if sender returns false' do
        allow(TelegramBot::Sender).to receive(:call).and_return(false)

        expect(service_call).to be(true)
      end
    end

    def expect_translation_call(locale:)
      expect(I18n).to have_received(:t).with(
        'telegram.notifier.player.left',
        locale: locale,
        icon: tournament.icon,
        player_name: player.full_name,
        team_name: team.human_name,
        tournament_name: tournament.name,
        code: tournament.code
      )
    end
  end
end
