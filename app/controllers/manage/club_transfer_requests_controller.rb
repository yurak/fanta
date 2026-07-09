module Manage
  class ClubTransferRequestsController < BaseController
    def index
      @status = ClubTransferRequest.statuses.key?(params[:status]) ? params[:status] : 'pending'
      order = @status == 'pending' ? { id: :asc } : { updated_at: :desc }
      @requests = ClubTransferRequest.where(status: @status)
                                     .includes(old_club: :tournament, new_club: :tournament, player: %i[teams club])
                                     .order(order)
      @requests = @requests.joins(:player).where('players.name ILIKE ?', "%#{params[:player_name]}%") if params[:player_name].present?
      @requests = @requests.page(params[:page]).per(PER_PAGE)
    end

    def confirm
      transfer_request = ClubTransferRequest.find(params.expect(:id))
      result = ClubTransfers::Applier.call(transfer_request)

      if result == :failed
        redirect_to list_path, alert: t('manage.club_transfer_requests.failed')
      else
        transfer_request.confirmed!
        redirect_to list_path, notice: t('manage.club_transfer_requests.confirmed')
      end
    end

    def reject
      transfer_request = ClubTransferRequest.find(params.expect(:id))
      transfer_request.rejected!

      redirect_to list_path, notice: t('manage.club_transfer_requests.rejected')
    end

    private

    def list_path
      manage_club_transfer_requests_path(
        params.permit(:status, :player_name, :page).to_h.compact_blank
      )
    end
  end
end
