RSpec.describe 'UserLogos' do
  let(:user) { create(:user) }
  let(:file) { fixture_file_upload('spec/fixtures/files/logo.png', 'image/png') }

  describe 'POST #create' do
    context 'when user is logged out' do
      it 'redirects to sign in' do
        post user_logos_path, params: { logo: file }
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    context 'when user is logged in' do
      before { sign_in user }

      context 'with a file' do
        before do
          allow(Teams::LogoUploader).to receive(:call).and_return(create(:user_logo, user: user))
          post user_logos_path, params: { logo: file }, headers: { 'HTTP_REFERER' => edit_team_path(create(:team, :with_user, user: user)) }
        end

        it { expect(response).to have_http_status(:found) }

        it 'calls the uploader for the current user' do
          expect(Teams::LogoUploader).to have_received(:call).with(hash_including(user: user))
        end
      end

      context 'without a file' do
        it 'does not call the uploader' do
          allow(Teams::LogoUploader).to receive(:call)
          post user_logos_path
          expect(Teams::LogoUploader).not_to have_received(:call)
        end
      end

      context 'when the file is invalid' do
        before do
          allow(Teams::LogoUploader).to receive(:call).and_raise(Teams::LogoUploader::InvalidFile, 'bad file')
          post user_logos_path, params: { logo: file }
        end

        it { expect(flash[:alert]).to eq('bad file') }
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:logo) { create(:user_logo, user: user) }

    context 'when user is logged in' do
      before { sign_in user }

      context 'when the logo is not used by a team' do
        before { delete user_logo_path(logo) }

        it 'soft-deletes the logo' do
          expect(logo.reload.discarded?).to be(true)
        end
      end

      context 'when the logo is used by a team' do
        before do
          create(:team, :with_user, user: user, logo_url: logo.url)
          delete user_logo_path(logo)
        end

        it 'does not delete the logo' do
          expect(logo.reload.discarded?).to be(false)
        end

        it { expect(flash[:alert]).to eq(I18n.t('user_logos.in_use')) }
      end
    end
  end
end
