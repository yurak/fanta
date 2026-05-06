RSpec.describe 'Links' do
  describe 'GET #index' do
    let!(:linked_tournament) { create(:tournament) }
    let!(:unlinked_tournament) { create(:tournament) }

    before do
      Link.create!(tournament: linked_tournament, name: 'Website', url: 'https://example.com')

      get links_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:tournaments)).to include(linked_tournament) }
    it { expect(assigns(:tournaments)).not_to include(unlinked_tournament) }
  end
end
