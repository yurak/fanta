RSpec.describe 'Manage::ClubTransferRequests' do
  let(:player) { create(:player) }
  let(:transfer_request) { create(:club_transfer_request, player: player) }

  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_club_transfer_requests_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user
      before { get manage_club_transfer_requests_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        transfer_request
        get manage_club_transfer_requests_path
      end

      it { expect(response).to have_http_status(:ok) }
    end

    context 'when filtering by a status tab' do
      login_admin
      before do
        create(:club_transfer_request, player: create(:player, name: 'PendingMarkerX'), status: :pending)
        create(:club_transfer_request, player: create(:player, name: 'ConfirmedMarkerX'), status: :confirmed)
        get manage_club_transfer_requests_path(status: 'confirmed')
      end

      it { expect(response.body).to include('ConfirmedMarkerX') }
      it { expect(response.body).not_to include('PendingMarkerX') }
    end

    context 'when viewing the confirmed tab' do
      login_admin
      before do
        older = create(:club_transfer_request, player: create(:player, name: 'OlderMarkerX'), status: :confirmed)
        newer = create(:club_transfer_request, player: create(:player, name: 'NewerMarkerX'), status: :confirmed)
        # rubocop:disable Rails/SkipsModelValidations
        older.update_column(:updated_at, 2.days.ago)
        newer.update_column(:updated_at, 1.hour.ago)
        # rubocop:enable Rails/SkipsModelValidations
        get manage_club_transfer_requests_path(status: 'confirmed')
      end

      it 'lists the most recently updated request first' do
        expect(response.body.index('NewerMarkerX')).to be < response.body.index('OlderMarkerX')
      end
    end
  end

  describe 'POST #confirm' do
    context 'when admin is logged in' do
      login_admin

      context 'when the change is applied' do
        before do
          allow(ClubTransfers::Applier).to receive(:call).and_return(:changed)
          post confirm_manage_club_transfer_request_path(transfer_request)
        end

        it { expect(transfer_request.reload).to be_confirmed }
        it { expect(flash[:notice]).to be_present }
      end

      context 'when applying fails' do
        before do
          allow(ClubTransfers::Applier).to receive(:call).and_return(:failed)
          post confirm_manage_club_transfer_request_path(transfer_request)
        end

        it { expect(transfer_request.reload).to be_pending }
        it { expect(flash[:alert]).to be_present }
      end

      context 'when the player is already in the new club' do
        before do
          allow(ClubTransfers::Applier).to receive(:call).and_return(:skipped)
          post confirm_manage_club_transfer_request_path(transfer_request)
        end

        it { expect(transfer_request.reload).to be_confirmed }
      end

      context 'when a page and tab are given' do
        before do
          allow(ClubTransfers::Applier).to receive(:call).and_return(:changed)
          post confirm_manage_club_transfer_request_path(transfer_request, page: 2, status: 'pending')
        end

        it 'redirects back to the same page and tab' do
          expect(response).to redirect_to(manage_club_transfer_requests_path(page: 2, status: 'pending'))
        end
      end
    end
  end

  describe 'POST #reject' do
    context 'when admin is logged in' do
      login_admin
      before { post reject_manage_club_transfer_request_path(transfer_request) }

      it { expect(transfer_request.reload).to be_rejected }
      it { expect(flash[:notice]).to be_present }
    end
  end
end
