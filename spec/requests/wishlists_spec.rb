RSpec.describe 'Wishlists' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get wishlists_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when user is logged in' do
      login_user

      before { get wishlists_path }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
    end
  end

  # The address of a list is public whatever its sharing setting: a guest following a link has to
  # reach the page, where the API tells him whether he may read the list.
  describe 'GET #show' do
    let(:wishlist) { create(:wishlist) }

    context 'when user is logged out' do
      before { get wishlist_path(wishlist) }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
    end

    context 'when user is logged in' do
      login_user

      before { get wishlist_path(wishlist) }

      it { expect(response).to be_successful }
    end
  end
end
