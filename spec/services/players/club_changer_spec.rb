RSpec.describe Players::ClubChanger do
  describe '#call' do
    subject(:service_call) { described_class.call(player: player, new_club_id: new_club.id) }

    let(:tournament) { create(:tournament) }
    let(:old_club) { create(:club, tournament: tournament) }
    let(:player) { create(:player, club: old_club) }

    context 'when moving to a club in the same tournament (same-tournament move)' do
      let(:new_club) { create(:club, tournament: tournament) }

      it 'updates the player club' do
        service_call
        expect(player.reload.club).to eq(new_club)
      end

      it 'does not create a club transfer record' do
        expect { service_call }.not_to change(ClubTransfer, :count)
      end

      it 'does not call Transfers::Seller' do
        allow(Transfers::Seller).to receive(:call)
        service_call
        expect(Transfers::Seller).not_to have_received(:call)
      end

      context 'with an owning team' do
        let(:league) { create(:league, tournament: tournament) }
        let(:team) { create(:team, league: league) }

        before { create(:player_team, player: player, team: team) }

        it 'notifies the team owner of the club change' do
          allow(TelegramBot::PlayerClubChangedNotifier).to receive(:call)
          service_call
          expect(TelegramBot::PlayerClubChangedNotifier).to have_received(:call).with(player, team, new_club)
        end
      end
    end

    context 'when moving to a club in a different tournament (cross-tournament move)' do
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

      it 'calls Transfers::Seller for each owning team' do
        allow(Transfers::Seller).to receive(:call)
        service_call
        expect(Transfers::Seller).to have_received(:call).with(player, team, :left)
      end

      it 'removes player from owning teams' do
        expect { service_call }.to change(PlayerTeam, :count).by(-1)
      end

      it 'does not notify a club change' do
        allow(TelegramBot::PlayerClubChangedNotifier).to receive(:call)
        service_call
        expect(TelegramBot::PlayerClubChangedNotifier).not_to have_received(:call)
      end
    end

    context 'when new_club_id does not exist' do
      let(:new_club) { build(:club, id: 999_999) }

      it { expect(service_call).to be(false) }
    end

    context 'when new club is the same as the current club' do
      let(:new_club) { old_club }

      it { expect(service_call).to be(false) }
    end

    context 'when old club has nil tournament_id' do
      let(:old_club) { create(:club, tournament: nil) }
      let(:new_club) { create(:club, tournament: tournament) }

      it 'updates the player club' do
        service_call
        expect(player.reload.club).to eq(new_club)
      end
    end

    context 'when new club has nil tournament_id' do
      let(:new_club) { create(:club, tournament: nil) }

      it 'updates the player club' do
        service_call
        expect(player.reload.club).to eq(new_club)
      end
    end
  end
end
