RSpec.describe 'Manage::Clubs' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_clubs_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_clubs_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      before do
        create(:club, name: 'Alpha Club')
        create(:club, name: 'Beta Club')
        get manage_clubs_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'shows Alpha Club when no filter' do
        expect(response.body).to include('Alpha Club')
      end

      it 'shows Beta Club when no filter' do
        expect(response.body).to include('Beta Club')
      end

      it 'filters clubs by name — shows match' do
        get manage_clubs_path, params: { name: 'Alpha' }
        expect(response.body).to include('Alpha Club')
      end

      it 'filters clubs by name — hides non-match' do
        get manage_clubs_path, params: { name: 'Alpha' }
        expect(response.body).not_to include('Beta Club')
      end

      it 'filters case-insensitively' do
        get manage_clubs_path, params: { name: 'alpha' }
        expect(response.body).to include('Alpha Club')
      end

      it 'shows reset link when name filter is applied' do
        get manage_clubs_path, params: { name: 'Alpha' }
        expect(response.body).to include(manage_clubs_path)
      end
    end

    context 'when filtering by tournament' do
      login_admin

      let(:tournament) { create(:tournament) }

      before do
        create(:club, name: 'InTourClub', tournament: tournament)
        create(:club, name: 'OtherTourClub', tournament: create(:tournament))
        get manage_clubs_path, params: { tournament_id: tournament.id }
      end

      it 'shows clubs from the selected tournament' do
        expect(response.body).to include('InTourClub')
      end

      it 'hides clubs from other tournaments' do
        expect(response.body).not_to include('OtherTourClub')
      end

      it 'also matches clubs by eurocup tournament' do
        create(:club, name: 'EcTourClub', tournament: nil, ec_tournament: tournament)
        get manage_clubs_path, params: { tournament_id: tournament.id }
        expect(response.body).to include('EcTourClub')
      end
    end

    context 'with the tournament column' do
      login_admin

      it 'renders the tournament as an icon carrying its name' do
        create(:club, name: 'IconClub', tournament: create(:tournament, name: 'Zzz Marker Cup'))
        get manage_clubs_path, params: { name: 'IconClub' }
        expect(response.body).to include('title="Zzz Marker Cup"')
      end

      it 'renders a dash when the club has no tournament' do
        create(:club, name: 'NoTourClub', tournament: nil)
        get manage_clubs_path, params: { name: 'NoTourClub' }
        expect(response.body).to include('—')
      end
    end

    context 'when filtering by status' do
      login_admin

      before do
        create(:club, name: 'ActiveMarkerClub', status: :active)
        create(:archived_club, name: 'ArchivedMarkerClub')
        get manage_clubs_path, params: { status: 'archived' }
      end

      it 'shows clubs with the selected status' do
        expect(response.body).to include('ArchivedMarkerClub')
      end

      it 'hides clubs with other statuses' do
        expect(response.body).not_to include('ActiveMarkerClub')
      end
    end

    context 'with status and TM columns' do
      login_admin

      let!(:club) { create(:club, name: 'TmMarkerClub', tm_url: 'https://www.transfermarkt.com/x/startseite/verein/1') }

      before { get manage_clubs_path }

      it 'shows the club status' do
        expect(response.body).to include(club.status)
      end

      it 'shows a TM link' do
        expect(response.body).to include(club.tm_url)
      end
    end
  end

  describe 'GET #show' do
    context 'when user is logged out' do
      let(:club) { create(:club) }

      before { get manage_club_path(club) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when admin is logged in' do
      login_admin

      let(:club) { create(:club, name: 'Test Club') }

      before do
        create(:player, club: club, name: 'Shevchenko')
        get manage_club_path(club)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }

      it 'displays club name' do
        expect(response.body).to include('Test Club')
      end

      it 'displays players list' do
        expect(response.body).to include('Shevchenko')
      end

      it 'displays players count' do
        expect(response.body).to include('1')
      end
    end
  end

  describe 'GET #sync_squad' do
    let(:club) { create(:club, tm_url: 'https://www.transfermarkt.com/x/startseite/verein/23826') }

    context 'when admin is logged in' do
      login_admin

      before do
        create(:player, tm_id: 111, name: 'ExistingMarker')
        allow(Players::Transfermarkt::ClubSquadParser).to receive(:call).and_return(%w[111 222])
        allow(Players::Transfermarkt::ApiParser).to receive(:call).and_return({ first_name: 'New', name: 'GuyMarker' })
        get sync_squad_manage_club_path(club)
      end

      it { expect(response).to be_successful }

      it 'marks an existing squad player as present' do
        expect(response.body).to include('ExistingMarker')
      end

      it 'shows a fetched name for an absent squad player' do
        expect(response.body).to include('GuyMarker')
      end
    end

    context 'when a squad player sits in another club in our base' do
      login_admin

      before do
        create(:player, tm_id: 111, club: create(:club, name: 'Free agent'))
        allow(Players::Transfermarkt::ClubSquadParser).to receive(:call).and_return(%w[111])
        get sync_squad_manage_club_path(club)
      end

      it 'highlights the row' do
        expect(response.body).to include('table-danger')
      end

      it 'names the club the player is assigned to' do
        expect(response.body).to include('Free agent')
      end
    end

    context 'when a squad player already belongs to the club' do
      login_admin

      before do
        create(:player, tm_id: 111, club: club)
        allow(Players::Transfermarkt::ClubSquadParser).to receive(:call).and_return(%w[111])
        get sync_squad_manage_club_path(club)
      end

      it 'does not highlight the row' do
        expect(response.body).not_to include('table-danger')
      end
    end

    context 'when Transfermarkt is unavailable' do
      login_admin

      before do
        allow(Players::Transfermarkt::ClubSquadParser)
          .to receive(:call).and_raise(Players::Transfermarkt::ApiError.new('boom', http_code: 504))
        get sync_squad_manage_club_path(club)
      end

      it 'redirects back to the club with the TM error code in the alert' do
        aggregate_failures do
          expect(response).to redirect_to(manage_club_path(club))
          expect(flash[:alert]).to include('504')
        end
      end
    end
  end

  describe 'POST #create_players' do
    let(:club) { create(:club) }

    context 'when admin is logged in' do
      login_admin

      before do
        allow(Players::Transfermarkt::ApiParser).to receive(:call).and_return({ name: 'Ronaldo', club_name: club.name })
        allow(Players::Manager).to receive(:call).and_return(true)
      end

      it 'creates each selected player' do
        post create_players_manage_club_path(club), params: { tm_ids: %w[222 333] }

        expect(Players::Manager).to have_received(:call).twice
      end

      it 'redirects to the club' do
        post create_players_manage_club_path(club), params: { tm_ids: %w[222 333] }

        expect(response).to redirect_to(manage_club_path(club))
      end

      it 'skips players that already exist' do
        create(:player, tm_id: 222)
        post create_players_manage_club_path(club), params: { tm_ids: %w[222] }

        expect(Players::Manager).not_to have_received(:call)
      end
    end
  end
end
