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
  end
end
