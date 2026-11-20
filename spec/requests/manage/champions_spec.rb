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

      let!(:first_champion) { create(:user, name: 'AliceChampionQA', champion_number: 1) }

      before do
        create(:user, name: 'BobChampionQA', champion_number: 2)
        create(:user, name: 'CarolChampionQA', champion_number: nil)
        get manage_champions_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'shows first champion' do
        expect(response.body).to include('AliceChampionQA')
      end

      it 'shows second champion' do
        expect(response.body).to include('BobChampionQA')
      end

      it 'excludes users without champion_number' do
        expect(response.body).not_to include('CarolChampionQA')
      end

      it 'orders champions by champion_number' do
        alice_pos = response.body.index('AliceChampionQA')
        bob_pos = response.body.index('BobChampionQA')
        expect(alice_pos).to be < bob_pos
      end

      context 'with the matrix tab' do
        # the suite seeds the tournaments, so the matrix columns come from the real ones
        let(:italy) { Tournament.find_by!(code: 'italy') }
        let(:spain) { Tournament.find_by!(code: 'spain') }

        before do
          create(:user_title, user: first_champion, tournament: italy, championship_number: 1, season: '2024/2025')
          create(:user_title, user: first_champion, tournament: italy, championship_number: 2, season: '2025/2026')
          create(:user_title, user: first_champion, tournament: spain, championship_number: 3, season: '2025/2026')
          get manage_champions_path(tab: 'matrix')
        end

        it { expect(response).to be_successful }
        it { expect(response.body).to include('champions-matrix') }

        it 'labels a season by its last two years' do
          expect(response.body).to include('24/25')
        end

        it 'shades a repeated title differently from a single one' do
          expect(response.body).to include('champions-matrix-shade-2')
        end

        it 'heads the tournament columns with their logos' do
          expect(response.body).to include('tournaments/italy')
        end

        it 'prints the id of every champion' do
          expect(response.body).to match(/champions-matrix-id[^>]*>\s*#{first_champion.id}\s*</)
        end

        it 'totals the titles of a champion' do
          expect(response.body).to match(/champions-matrix-total[^>]*>\s*3\s*</)
        end
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
