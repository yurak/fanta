RSpec.describe 'Leagues' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before do
        get leagues_path
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get leagues_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'GET #show' do
    let(:league) { create(:league) }

    context 'when user is logged out' do
      before do
        get league_path(league)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get league_path(league)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:league)).not_to be_nil }
      it { expect(assigns(:league)).to eq(league) }
    end
  end

  describe 'PUT #activate' do
    let(:league) { create(:league) }
    let(:parser) { instance_double(Leagues::Activator) }

    before do
      put activate_league_path(league)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        put activate_league_path(league)
      end

      it { expect(response).to redirect_to(league_path(league)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        put activate_league_path(league)
      end

      it { expect(response).to redirect_to(league_path(league)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        allow(Leagues::Activator).to receive(:new).with(league.id).and_return(parser)
        allow(parser).to receive(:call).and_return([])

        put activate_league_path(league)
      end

      it { expect(response).to redirect_to(league_path(league)) }
      it { expect(response).to have_http_status(:found) }
    end
  end
end
