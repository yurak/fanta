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
          expect(response.body).to include(player.name)
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
        expect(response.body).to include(player.name)
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

  describe 'POST #create' do
    let(:club) { create(:club, name: 'NY Red Bulls') }
    let(:valid_hash) do
      {
        'first_name' => 'Julian', 'name' => 'Bazan', 'nationality' => 'co',
        'club_id' => club.id, 'club_name' => club.name, 'position1' => 'Dc',
        'position2' => nil, 'position3' => nil,
        'tm_url' => 'https://www.transfermarkt.com/player-path/profil/spieler/1097930',
        'tm_pos1' => 'CB', 'tm_pos2' => nil, 'tm_pos3' => nil,
        'tm_price' => 750_000.0, 'number' => 0, 'birth_date' => '25/11/2005',
        'height' => 183, 'tm_club_name' => 'New York'
      }
    end
    let(:valid_player_hash_str) do
      valid_hash.inspect
    end

    context 'when user is logged out' do
      before { post manage_players_path, params: { player_hash: valid_player_hash_str } }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { post manage_players_path, params: { player_hash: valid_player_hash_str } }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      context 'with a valid Ruby hash string' do
        before do
          club
          allow(Players::Manager).to receive(:call).and_return(true)
          post manage_players_path, params: { player_hash: valid_player_hash_str }
        end

        it { expect(response).to redirect_to(manage_players_path) }
        it { expect(flash[:notice]).to be_present }

        it 'calls Players::Manager with the parsed hash' do
          expect(Players::Manager).to have_received(:call).with(hash_including('name' => 'Bazan'))
        end
      end

      context 'when Players::Manager returns false' do
        before do
          allow(Players::Manager).to receive(:call).and_return(false)
          post manage_players_path, params: { player_hash: valid_player_hash_str }
        end

        it { expect(response).to redirect_to(manage_players_path) }
        it { expect(flash[:alert]).to be_present }
      end

      context 'with an invalid hash string' do
        before { post manage_players_path, params: { player_hash: 'not a hash at all!!!' } }

        it { expect(response).to redirect_to(manage_players_path) }
        it { expect(flash[:alert]).to be_present }
      end

      context 'with a blank hash string' do
        before { post manage_players_path, params: { player_hash: '' } }

        it { expect(response).to redirect_to(manage_players_path) }
        it { expect(flash[:alert]).to be_present }
      end
    end
  end
end
