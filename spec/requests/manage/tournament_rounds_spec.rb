RSpec.describe 'Manage::TournamentRounds' do
  describe 'GET #index' do
    context 'when logged out' do
      before { get manage_tournament_rounds_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_tournament_rounds_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      context 'without live tours' do
        before { get manage_tournament_rounds_path }

        it { expect(response).to be_successful }
        it { expect(response).to render_template(:index) }
      end

      context 'with a live tour' do
        let(:round) { create(:tournament_round) }

        before do
          create(:tour, tournament_round: round, status: :postponed)
          get manage_tournament_rounds_path
        end

        it { expect(response).to be_successful }

        it 'renders the status chip label' do
          expect(response.body).to include(I18n.t('manage.tournament_rounds.status.postponed'))
        end
      end

      context 'with an upcoming (inactive) tour' do
        let(:round) { create(:tournament_round, deadline: Time.utc(2026, 12, 22, 20, 30)) }

        before do
          create(:tour, tournament_round: round, status: :inactive)
          get manage_tournament_rounds_path
        end

        it { expect(response).to be_successful }

        it 'renders the round deadline for the first not-opened round' do
          expect(response.body).to include('22/12/26')
        end
      end

      context 'with an open (set_lineup) tour' do
        let(:round) { create(:tournament_round, deadline: Time.utc(2026, 12, 22, 20, 30)) }

        before do
          create(:tour, tournament_round: round, status: :set_lineup)
          get manage_tournament_rounds_path
        end

        it { expect(response).to be_successful }

        it 'renders the deadline so admins see when lineups close' do
          expect(response.body).to include('20:30 22/12/26')
        end
      end

      context 'with a moderated locked tour' do
        let(:round) { create(:tournament_round, moderated_at: Time.utc(2026, 12, 22, 20, 30)) }

        before do
          create(:tour, tournament_round: round, status: :locked)
          get manage_tournament_rounds_path
        end

        it { expect(response).to be_successful }

        it 'renders the moderation time plus 18 hours' do
          # the admin factory uses the default UTC zone: 20:30 UTC Dec 22 + 18h = 14:30 Dec 23
          expect(response.body).to include('14:30 23/12/26')
        end
      end

      context 'with a moderated postponed tour' do
        let(:round) { create(:tournament_round, moderated_at: Time.utc(2026, 12, 22, 20, 30)) }

        before do
          create(:tour, tournament_round: round, status: :postponed)
          get manage_tournament_rounds_path
        end

        it { expect(response).to be_successful }

        it 'renders the closing time just like a locked tour' do
          expect(response.body).to include('14:30 23/12/26')
        end
      end

      context 'with a postponed tour that was never moderated' do
        let(:round) { create(:tournament_round, moderated_at: nil, deadline: Time.utc(2026, 12, 22, 20, 30)) }

        before do
          create(:tour, tournament_round: round, status: :postponed)
          get manage_tournament_rounds_path
        end

        it 'shows no closing time' do
          expect(response.body).not_to include('14:30 23/12/26')
        end
      end
    end
  end
end
