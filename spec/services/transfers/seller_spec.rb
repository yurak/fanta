RSpec.describe Transfers::Seller do
  describe '#call' do
    subject(:service_call) { described_class.new(player, team, status).call }

    let(:league) { create(:league) }
    let(:team) { create(:team, league: league, budget: 100) }
    let(:player) { create(:player) }
    let(:status) { :outgoing }

    context 'when init transfer is missing' do
      before do
        create(:auction, league: league)
        create(:player_team, player: player, team: team)
      end

      it 'does not create outgoing transfer' do
        expect { service_call }.not_to change(Transfer, :count)
      end
    end

    context 'when player team relation is missing' do
      before do
        create(:auction, league: league)
        create(:transfer, :incoming, player: player, team: team, league: league, price: 25)
      end

      it 'does not create outgoing transfer' do
        expect { service_call }.not_to change(Transfer, :count)
      end
    end

    context 'when initial sales auction is missing' do
      before do
        create(:transfer, :incoming, player: player, team: team, league: league, price: 25)
        create(:player_team, player: player, team: team)
        create(:auction, league: league, status: :closed)
      end

      it 'does not create outgoing transfer' do
        expect { service_call }.not_to change(Transfer, :count)
      end
    end

    context 'when all prerequisites are present' do
      let(:sale_price) { 25 }

      before do
        create(:transfer, :incoming, player: player, team: team, league: league, price: sale_price)
        create(:player_team, player: player, team: team)
        create(:auction, league: league, status: :initial)
      end

      it 'creates transfer' do
        expect { service_call }.to change(Transfer, :count).by(1)
      end

      it 'creates transfer with expected status' do
        service_call

        expect(Transfer.by_player(player.id).last).to be_outgoing
      end

      it 'creates transfer with init transfer price' do
        service_call

        expect(Transfer.by_player(player.id).last.price).to eq(sale_price)
      end

      it 'increases team budget by init transfer price' do
        expect { service_call }.to change { team.reload.budget }.by(sale_price)
      end

      it 'removes player from team' do
        expect { service_call }.to change(PlayerTeam, :count).by(-1)
      end

      it 'does not notify telegram bot for outgoing status' do
        allow(TelegramBot::PlayerSoldNotifier).to receive(:call)

        service_call

        expect(TelegramBot::PlayerSoldNotifier).not_to have_received(:call)
      end

      context 'when status is left' do
        let(:status) { :left }

        it 'notifies telegram bot' do
          allow(TelegramBot::PlayerSoldNotifier).to receive(:call)

          service_call

          expect(TelegramBot::PlayerSoldNotifier).to have_received(:call).with(player, team)
        end
      end
    end
  end
end
