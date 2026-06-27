module Manage
  class ClubTransfersController < BaseController
    def index
      @club_transfers = ClubTransfer.includes(:player, :old_club, :new_club)
                                    .order(id: :desc)
      if params[:player_name].present?
        @club_transfers = @club_transfers.joins(:player)
                                         .where('players.name ILIKE ?', "%#{params[:player_name]}%")
      end
      if params[:club_name].present?
        @club_transfers = @club_transfers.where(
          'old_club_name ILIKE :q OR new_club_name ILIKE :q', q: "%#{params[:club_name]}%"
        )
      end
      @club_transfers = @club_transfers.page(params[:page]).per(PER_PAGE)
    end

    def create
      player = Player.find(params.expect(:player_id))
      result = Players::ClubChanger.call(
        player: player,
        new_club_id: club_transfer_params[:new_club_id],
        start_date: club_transfer_params[:start_date],
        contract_expires_on: club_transfer_params[:contract_expires_on],
        loan: club_transfer_params[:loan] == '1'
      )

      if result
        redirect_to manage_player_path(player), notice: t('manage.club_transfers.created')
      else
        redirect_to manage_player_path(player), alert: t('manage.club_transfers.failed')
      end
    end

    private

    def club_transfer_params
      params.permit(:new_club_id, :start_date, :contract_expires_on, :loan)
    end
  end
end
