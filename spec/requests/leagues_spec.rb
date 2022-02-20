RSpec.describe 'Leagues', type: :request do
  describe 'GET #index' do
    before do
      get leagues_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to have_http_status(:ok) }
  end

  describe 'GET #show' do
    let(:league) { create(:league) }

    before do
      get league_path(league)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:league)).not_to be_nil }
    it { expect(assigns(:league)).to eq(league) }
  end
end
