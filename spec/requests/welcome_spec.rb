RSpec.describe 'Welcome', type: :request do
  describe 'GET #index(root)' do
    before do
      get root_path
    end

    context 'when user is logged out' do
      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to render_template(:_footer) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when user without active league is logged in' do
      login_user
      before do
        get root_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to render_template(:_footer) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when user with active league is logged in' do
      login_user

      before do
        user = User.last
        team = create(:team, user: user)
        create_list(:tour, 3, league: team.league)

        get root_path
      end

      it do
        tour = User.last.active_league.active_tour_or_last

        expect(response).to redirect_to(tour_path(tour))
      end

      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'GET #about' do
    before do
      get about_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:about) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to render_template(:_footer) }
    it { expect(response).to have_http_status(:ok) }
  end

  describe 'GET #contact' do
    before do
      get contact_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:contact) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to render_template(:_footer) }
    it { expect(response).to have_http_status(:ok) }
  end

  describe 'GET #guide' do
    before do
      get guide_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:guide) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to render_template(:_footer) }
    it { expect(response).to have_http_status(:ok) }
  end

  describe 'GET #rules' do
    before do
      get rules_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:rules) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to render_template(:_footer) }
    it { expect(response).to have_http_status(:ok) }
  end
end
