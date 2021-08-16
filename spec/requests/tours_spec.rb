RSpec.describe 'Tours', type: :request do
  let(:tour) { create(:tour) }

  describe 'GET #show' do
    before do
      get tour_path(tour)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:tournament_players)).not_to be_nil }
    it { expect(assigns(:league_players)).not_to be_nil }
  end

  describe 'GET #edit' do
    before do
      get edit_tour_path(tour)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get edit_tour_path(tour)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get edit_tour_path(tour)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with not set_lineup tour when admin is logged in' do
      login_admin
      before do
        get edit_tour_path(tour)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with set_lineup tour when admin is logged in' do
      let(:tour) { create(:set_lineup_tour) }

      login_admin
      before do
        get edit_tour_path(tour)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:deadline) { FFaker::Time.datetime }
    let(:params) do
      {
        tour: {
          deadline: deadline
        }
      }
    end

    before do
      put tour_path(tour, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        put tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        put tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        put tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates tour with specified deadline' do
        expect(tour.reload.deadline).to eq(deadline)
      end
    end
  end

  describe 'GET #change_status' do
    let(:status) { 'set_lineup' }
    let(:params) { { status: status } }

    before do
      get change_status_tour_path(tour, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get change_status_tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update tour with specified status' do
        expect(tour.reload.status).not_to eq(status)
      end
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get change_status_tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update tour with specified status' do
        expect(tour.reload.status).not_to eq(status)
      end
    end

    context 'with valid tour status when admin is logged in' do
      login_admin
      before do
        get change_status_tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates tour with specified status' do
        expect(tour.reload.status).to eq(status)
      end

      it 'calls Tours::Manager service' do
        manager = instance_double(Tours::Manager)
        allow(Tours::Manager).to receive(:new).and_return(manager)
        allow(manager).to receive(:call).and_return(tour)

        get change_status_tour_path(tour, params)
      end
    end

    context 'with not valid tour status when admin is logged in' do
      let(:status) { 'closed' }

      login_admin
      before do
        get change_status_tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'calls Tours::Manager service' do
        manager = instance_double(Tours::Manager)
        allow(Tours::Manager).to receive(:new).and_return(manager)
        allow(manager).to receive(:call).and_return(tour)

        get change_status_tour_path(tour, params)
      end

      it 'does not update tour with specified status' do
        expect(tour.reload.status).not_to eq(status)
      end
    end
  end

  describe 'GET #inject_scores' do
    let(:strategy) { instance_double(Scores::Injectors::Strategy) }
    let(:klass) { class_double(Scores::Injectors::Calcio) }

    before do
      get inject_scores_tour_path(tour)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get inject_scores_tour_path(tour)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get inject_scores_tour_path(tour)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'calls Strategy service' do
        allow(Scores::Injectors::Strategy).to receive(:new).with(tour).and_return(strategy)
        allow(strategy).to receive(:call).and_return(klass)
        allow(klass).to receive(:call).and_return('data')

        get inject_scores_tour_path(tour)
      end

      it 'calls Updater service' do
        allow(Scores::PositionMalus::Updater).to receive(:call)

        get inject_scores_tour_path(tour)
      end
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get inject_scores_tour_path(tour)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'calls Strategy service' do
        allow(Scores::Injectors::Strategy).to receive(:new).with(tour).and_return(strategy)
        allow(strategy).to receive(:call).and_return(klass)
        allow(klass).to receive(:call).and_return('data')

        get inject_scores_tour_path(tour)
      end

      it 'calls Updater service' do
        allow(Scores::PositionMalus::Updater).to receive(:call)

        get inject_scores_tour_path(tour)
      end
    end
  end
end
