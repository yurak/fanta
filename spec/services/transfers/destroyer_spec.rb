RSpec.describe Transfers::Destroyer do
  describe '#call' do
    subject(:service_call) { described_class.new(transfer_id).call }

    let(:league) { create(:league) }
    let(:team) { create(:team, league: league, budget: 100) }
    let(:player) { create(:player) }
    let(:transfer_price) { 25 }
    let(:transfer) { create(:transfer, player: player, team: team, league: league, price: transfer_price) }
    let(:transfer_id) { transfer.id }

    context 'when transfer is missing' do
      let(:transfer_id) { 0 }

      it 'returns false' do
        expect(service_call).to be(false)
      end
    end

    context 'when transfer exists and player team relation exists' do
      before do
        transfer
        create(:player_team, player: player, team: team)
      end

      it 'destroys transfer' do
        expect { service_call }.to change(Transfer, :count).by(-1)
      end

      it 'destroys player team relation' do
        expect { service_call }.to change(PlayerTeam, :count).by(-1)
      end

      it 'increases team budget by transfer price' do
        expect { service_call }.to change { team.reload.budget }.by(transfer_price)
      end
    end

    context 'when transfer exists but player team relation is missing' do
      before do
        transfer
      end

      it 'raises an error' do
        expect { service_call }.to raise_error(NoMethodError)
      end

      it 'does not change transfer count' do
        expect do
          service_call
        rescue NoMethodError
          nil
        end.not_to change(Transfer, :count)
      end

      it 'does not change team budget because transaction is rolled back' do
        expect do
          service_call
        rescue NoMethodError
          nil
        end.not_to(change { team.reload.budget })
      end
    end
  end
end
