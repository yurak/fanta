RSpec.describe Players::ClubChanger do
  describe '#call' do
    subject(:service_call) do
      described_class.call(
        player: player,
        new_club_id: new_club.id,
        start_date: start_date,
        contract_expires_on: contract_expires_on,
        loan: loan
      )
    end

    let(:tournament) { create(:tournament) }
    let(:old_club) { create(:club, tournament: tournament) }
    let(:player) { create(:player, club: old_club) }
    let(:start_date) { Time.zone.today }
    let(:contract_expires_on) { '2027-06-30' }
    let(:loan) { false }

    context 'when moving to a club in the same tournament (same-tournament move)' do
      let(:new_club) { create(:club, tournament: tournament) }

      it 'updates the player club' do
        service_call
        expect(player.reload.club).to eq(new_club)
      end

      it 'creates a club transfer record' do
        expect { service_call }.to change(ClubTransfer, :count).by(1)
      end

      it 'sets correct old club on transfer' do
        service_call
        expect(ClubTransfer.last.old_club).to eq(old_club)
      end

      it 'sets correct new club on transfer' do
        service_call
        expect(ClubTransfer.last.new_club).to eq(new_club)
      end

      it 'saves start_date on transfer' do
        service_call
        expect(ClubTransfer.last.start_date).to eq(start_date)
      end

      it 'saves contract_expires_on on transfer' do
        service_call
        expect(ClubTransfer.last.contract_expires_on).to eq(Date.parse(contract_expires_on))
      end

      it 'does not call Transfers::Seller' do
        allow(Transfers::Seller).to receive(:call)
        service_call
        expect(Transfers::Seller).not_to have_received(:call)
      end

      context 'when loan is true' do
        let(:loan) { true }

        it 'saves loan flag on transfer' do
          service_call
          expect(ClubTransfer.last).to be_loan
        end
      end
    end

    context 'when moving to a club in a different tournament (cross-tournament move)' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:other_tournament) { create(:tournament) }
      let(:new_club) { create(:club, tournament: other_tournament) }
      let(:league) { create(:league, tournament: tournament) }
      let(:team) { create(:team, league: league) }

      before do
        create(:player_team, player: player, team: team)
        create(:transfer, :incoming, player: player, team: team, league: league, price: 50)
        create(:auction, league: league, status: :closed)
      end

      it 'updates the player club' do
        service_call
        expect(player.reload.club).to eq(new_club)
      end

      it 'creates a club transfer record' do
        expect { service_call }.to change(ClubTransfer, :count).by(1)
      end

      it 'calls Transfers::Seller for each owning team' do
        allow(Transfers::Seller).to receive(:call)
        service_call
        expect(Transfers::Seller).to have_received(:call).with(player, team, :left)
      end

      it 'removes player from owning teams' do
        expect { service_call }.to change(PlayerTeam, :count).by(-1)
      end
    end

    context 'when new_club_id does not exist' do
      let(:new_club) { build(:club, id: 999_999) }

      it 'returns false' do
        expect(service_call).to be(false)
      end

      it 'does not create a club transfer record' do
        expect { service_call }.not_to change(ClubTransfer, :count)
      end
    end

    context 'when new club is the same as the current club' do
      let(:new_club) { old_club }

      it 'returns false' do
        expect(service_call).to be(false)
      end

      it 'does not create a club transfer record' do
        expect { service_call }.not_to change(ClubTransfer, :count)
      end
    end

    context 'when old club has nil tournament_id' do
      let(:old_club) { create(:club, tournament: nil) }
      let(:new_club) { create(:club, tournament: tournament) }

      it 'returns true' do
        expect(service_call).to be(true)
      end

      it 'updates the player club' do
        service_call
        expect(player.reload.club).to eq(new_club)
      end

      it 'creates a club transfer record' do
        expect { service_call }.to change(ClubTransfer, :count).by(1)
      end
    end

    context 'when new club has nil tournament_id' do
      let(:new_club) { create(:club, tournament: nil) }

      it 'returns true' do
        expect(service_call).to be(true)
      end

      it 'updates the player club' do
        service_call
        expect(player.reload.club).to eq(new_club)
      end

      it 'creates a club transfer record' do
        expect { service_call }.to change(ClubTransfer, :count).by(1)
      end
    end

    context 'when both clubs have nil tournament_id' do
      let(:old_club) { create(:club, tournament: nil) }
      let(:new_club) { create(:club, tournament: nil) }

      it 'returns true' do
        expect(service_call).to be(true)
      end

      it 'updates the player club' do
        service_call
        expect(player.reload.club).to eq(new_club)
      end

      it 'creates a club transfer record' do
        expect { service_call }.to change(ClubTransfer, :count).by(1)
      end

      it 'calls Transfers::Seller for each team' do # rubocop:disable RSpec/ExampleLength
        league = create(:league, tournament: tournament)
        team   = create(:team, league: league)
        create(:player_team, player: player, team: team)
        create(:transfer, :incoming, player: player, team: team, league: league, price: 10)
        create(:auction, league: league, status: :closed)
        allow(Transfers::Seller).to receive(:call)
        service_call
        expect(Transfers::Seller).to have_received(:call).with(player, team, :left)
      end
    end
  end
end
