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

      it 'shows reset link when name filter is applied' do
        get manage_clubs_path, params: { name: 'Alpha' }
        expect(response.body).to include(manage_clubs_path)
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
end
