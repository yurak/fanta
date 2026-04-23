RSpec.describe 'Manage::TeamOfWeeks' do
  describe 'GET #index' do
    context 'when logged out' do
      before { get manage_team_of_weeks_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_team_of_weeks_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      context 'without round selection' do
        before { get manage_team_of_weeks_path }

        it { expect(response).to be_successful }
        it { expect(response).to render_template(:index) }

        it 'does not build teams' do
          expect(controller.instance_variable_get(:@teams)).to be_nil
        end

        it 'assigns rounds' do
          expect(controller.instance_variable_get(:@rounds)).not_to be_nil
        end
      end

      context 'with round_ids param' do
        let(:round) { create(:tournament_round) }

        before { get manage_team_of_weeks_path(round_ids: [round.id]) }

        it { expect(response).to be_successful }

        it 'builds teams' do
          expect(controller.instance_variable_get(:@teams)).not_to be_nil
        end

        it 'defaults to top mode' do
          expect(controller.instance_variable_get(:@mode)).to eq(:top)
        end
      end

      context 'with flop mode' do
        let(:round) { create(:tournament_round) }

        before { get manage_team_of_weeks_path(round_ids: [round.id], mode: 'flop') }

        it 'sets flop mode' do
          expect(controller.instance_variable_get(:@mode)).to eq(:flop)
        end
      end

      context 'with blank round_ids param' do
        before { get manage_team_of_weeks_path(round_ids: ['']) }

        it 'does not build teams' do
          expect(controller.instance_variable_get(:@teams)).to be_nil
        end
      end
    end
  end
end
