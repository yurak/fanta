RSpec.describe 'Manage::UserLogos' do
  let(:owner) { create(:user) }
  let!(:logo) { create(:user_logo, user: owner, status: :pending) }

  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_user_logos_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_user_logos_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      it { expect(get(manage_user_logos_path)).to eq(200) }

      it 'lists pending logos' do
        get manage_user_logos_path(tab: 'pending')
        expect(response.body).to include(CGI.escapeHTML(owner.name))
      end

      it 'shows archived logos in the archived tab' do
        logo.discard
        get manage_user_logos_path(tab: 'archived')
        expect(response.body).to include(logo.url)
      end

      context 'with more logos than one page' do
        before { create_list(:user_logo, Manage::BaseController::PER_PAGE, user: owner, status: :pending) }

        it 'limits the first page to PER_PAGE entries' do
          get manage_user_logos_path(tab: 'pending')
          expect(assigns(:user_logos).size).to eq(Manage::BaseController::PER_PAGE)
        end

        it 'shows the remaining entries on the second page' do
          get manage_user_logos_path(tab: 'pending', page: 2)
          expect(assigns(:user_logos).size).to eq(1)
        end
      end
    end
  end

  describe 'POST #approve' do
    login_admin

    before { allow(TelegramBot::LogoNotifier).to receive(:call) }

    it 'marks the logo approved' do
      post approve_manage_user_logo_path(logo)
      expect(logo.reload).to be_approved
    end

    it 'notifies the owner' do
      post approve_manage_user_logo_path(logo)
      expect(TelegramBot::LogoNotifier).to have_received(:call).with(logo)
    end
  end

  describe 'POST #reject' do
    login_admin

    before { allow(TelegramBot::LogoNotifier).to receive(:call) }

    it 'marks the logo rejected' do
      post reject_manage_user_logo_path(logo)
      expect(logo.reload).to be_rejected
    end

    it 'notifies the owner' do
      post reject_manage_user_logo_path(logo)
      expect(TelegramBot::LogoNotifier).to have_received(:call).with(logo)
    end
  end

  describe 'moderating an already-moderated logo' do
    login_admin

    let!(:logo) { create(:user_logo, user: owner, status: :approved) }

    before { allow(TelegramBot::LogoNotifier).to receive(:call) }

    it 'does not change the status' do
      post reject_manage_user_logo_path(logo)
      expect(logo.reload).to be_approved
    end

    it 'does not send a notification' do
      post reject_manage_user_logo_path(logo)
      expect(TelegramBot::LogoNotifier).not_to have_received(:call)
    end
  end
end
