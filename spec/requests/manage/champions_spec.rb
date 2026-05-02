RSpec.describe 'Manage::Champions' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_champions_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_champions_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      let!(:first_champion) { create(:user, name: 'Alice', champion_number: 1) }

      before do
        create(:user, name: 'Bob', champion_number: 2)
        create(:user, name: 'Carol', champion_number: nil)
        get manage_champions_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'shows first champion' do
        expect(response.body).to include('Alice')
      end

      it 'shows second champion' do
        expect(response.body).to include('Bob')
      end

      it 'excludes users without champion_number' do
        expect(response.body).not_to include('Carol')
      end

      it 'orders champions by champion_number' do
        alice_pos = response.body.index('Alice')
        bob_pos = response.body.index('Bob')
        expect(alice_pos).to be < bob_pos
      end

      context 'when champion has user_titles' do
        before do
          create(:user_title, user: first_champion, championship_number: 1, season: '2023/24')
          get manage_champions_path
        end

        it 'shows championship number' do
          expect(response.body).to include('#1')
        end

        it 'shows season in tooltip' do
          expect(response.body).to include('2023/24')
        end
      end
    end
  end
end
