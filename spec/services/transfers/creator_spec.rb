RSpec.describe Transfers::Creator do
  describe '#call' do
    subject(:creator) { described_class.new(league, params) }

    let(:league) { create(:league) }
    let(:team)   { create(:team, league: league, budget: Team::DEFAULT_BUDGET) }
    let(:player) { create(:player) }
    let(:price)  { 10 }
    let(:params) { { team_id: team.id, player_id: player.id, price: price } }

    context 'when player_id is invalid' do
      let(:params) { { team_id: team.id, player_id: 0, price: price } }

      it { expect(creator.call).to be(false) }

      it 'does not create a transfer' do
        expect { creator.call }.not_to change(Transfer, :count)
      end
    end

    context 'when team_id is invalid' do
      let(:params) { { team_id: 0, player_id: player.id, price: price } }

      it { expect(creator.call).to be(false) }

      it 'does not create a transfer' do
        expect { creator.call }.not_to change(Transfer, :count)
      end
    end

    context 'when team has a full squad' do
      let(:team) { create(:team, :with_full_squad, league: league, budget: Team::DEFAULT_BUDGET) }

      it { expect(creator.call).to be(false) }

      it 'does not create a transfer' do
        expect { creator.call }.not_to change(Transfer, :count)
      end
    end

    context 'when price is 0' do
      let(:price) { 0 }

      it { expect(creator.call).to be(false) }
    end

    context 'when price is negative' do
      let(:price) { -1 }

      it { expect(creator.call).to be(false) }
    end

    context 'when price exceeds max_rate' do
      let(:price) { team.max_rate + 1 }

      it { expect(creator.call).to be(false) }

      it 'does not create a transfer' do
        expect { creator.call }.not_to change(Transfer, :count)
      end
    end

    context 'when player already belongs to a team in this league' do
      before { create(:player_team, player: player, team: team) }

      it { expect(creator.call).to be(false) }

      it 'does not create a transfer' do
        expect { creator.call }.not_to change(Transfer, :count)
      end
    end

    context 'with valid params' do
      it 'returns truthy' do
        expect(creator.call).to be_truthy
      end

      it 'creates a transfer record' do
        expect { creator.call }.to change(Transfer, :count).by(1)
      end

      it 'creates a player_team record' do
        expect { creator.call }.to change(PlayerTeam, :count).by(1)
      end

      it 'assigns player to the correct team in the league' do
        creator.call
        expect(player.team_by_league(league.id)).to eq(team)
      end

      it 'deducts price from team budget' do
        expect { creator.call }.to change { team.reload.budget }.by(-price)
      end
    end

    context 'when player belongs to a team in another league' do
      let(:other_league) { create(:league) }
      let(:other_team)   { create(:team, league: other_league) }

      before { create(:player_team, player: player, team: other_team) }

      it 'returns truthy (different league is allowed)' do
        expect(creator.call).to be_truthy
      end

      it 'creates a transfer' do
        expect { creator.call }.to change(Transfer, :count).by(1)
      end
    end
  end
end
