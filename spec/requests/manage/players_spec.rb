RSpec.describe 'Manage::Players' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_players_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_players_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      before { get manage_players_path }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      context 'with name filter' do
        before { create(:player, name: 'Messi') }

        it 'returns matching players' do
          get manage_players_path, params: { name: 'Mess' }
          expect(response.body).to include('Messi')
        end

        it 'excludes non-matching players' do
          create(:player, name: 'Ronaldo')
          get manage_players_path, params: { name: 'Mess' }
          expect(response.body).not_to include('Ronaldo')
        end
      end

      context 'with club filter' do
        let!(:club) { create(:club) }
        let!(:player) { create(:player, club: club) }

        it 'returns players from the selected club' do
          get manage_players_path, params: { club_id: club.id }
          expect(response.body).to include(CGI.escapeHTML(player.name))
        end
      end
    end
  end

  describe 'GET #show' do
    let(:player) { create(:player) }

    context 'when user is logged out' do
      before { get manage_player_path(player) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_player_path(player) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      before { get manage_player_path(player) }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }

      it 'displays player name' do
        expect(response.body).to include(CGI.escapeHTML(player.name))
      end

      context 'with club transfer history' do
        let(:old_club) { create(:club) }
        let(:new_club) { create(:club) }

        before do
          create(:club_transfer, player: player, old_club: old_club, new_club: new_club)
          get manage_player_path(player)
        end

        it 'shows old club name' do
          expect(response.body).to include(CGI.escapeHTML(old_club.name))
        end

        it 'shows new club name' do
          expect(response.body).to include(CGI.escapeHTML(new_club.name))
        end
      end
    end
  end

  describe 'GET #fotmob_search' do
    let(:player) { create(:player, name: 'Haaland') }

    context 'when admin is logged in' do
      login_admin

      before do
        allow(Players::Fotmob::IdFinder).to receive(:call)
          .and_return([{ id: '737066', name: 'Erling Haaland', team_name: 'Man City' }])
        get fotmob_search_manage_player_path(player)
      end

      it { expect(response).to be_successful }

      it 'lists a candidate id' do
        expect(response.body).to include('737066')
      end
    end
  end

  describe 'POST #update_fotmob' do
    let(:player) { create(:player) }

    context 'when admin is logged in' do
      login_admin

      it 'saves the fotmob id' do
        post update_fotmob_manage_player_path(player, fotmob_id: '737066')

        expect(player.reload.fotmob_id).to eq(737_066)
      end

      it 'redirects to the player' do
        post update_fotmob_manage_player_path(player, fotmob_id: '737066')

        expect(response).to redirect_to(manage_player_path(player))
      end

      it 'alerts when the id is already used by another player' do
        create(:player, fotmob_id: 737_066)
        post update_fotmob_manage_player_path(player, fotmob_id: '737066')

        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'POST #create' do
    context 'when user is logged out' do
      before { post manage_players_path, params: { tm_id: '1097930' } }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { post manage_players_path, params: { tm_id: '1097930' } }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      context 'with a valid TM id' do
        before do
          allow(Players::Transfermarkt::ApiParser).to receive(:call).and_return({ name: 'Bazan', club_name: 'X' })
          allow(Players::Manager).to receive(:call).and_return(true)
          post manage_players_path, params: { tm_id: '1097930' }
        end

        it { expect(response).to redirect_to(manage_players_path) }
        it { expect(flash[:notice]).to be_present }

        it 'fetches the player data from TM by id' do
          expect(Players::Transfermarkt::ApiParser).to have_received(:call).with('1097930')
        end

        it 'creates the player via Players::Manager' do
          expect(Players::Manager).to have_received(:call).with(hash_including('name' => 'Bazan'))
        end
      end

      context 'when Players::Manager returns false' do
        before do
          allow(Players::Transfermarkt::ApiParser).to receive(:call).and_return({ name: 'Bazan' })
          allow(Players::Manager).to receive(:call).and_return(false)
          post manage_players_path, params: { tm_id: '1097930' }
        end

        it { expect(response).to redirect_to(manage_players_path) }
        it { expect(flash[:alert]).to be_present }
      end

      context 'when the TM id returns no data' do
        before do
          allow(Players::Transfermarkt::ApiParser).to receive(:call).and_return(false)
          post manage_players_path, params: { tm_id: '999' }
        end

        it { expect(response).to redirect_to(manage_players_path) }
        it { expect(flash[:alert]).to be_present }
      end
    end
  end
end
