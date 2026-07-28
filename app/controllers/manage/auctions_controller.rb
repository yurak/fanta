module Manage
  class AuctionsController < Manage::BaseController
    STATUSES = %w[initial sales blind_bids live closed].freeze

    def index
      @status = STATUSES.include?(params[:status]) ? params[:status] : 'initial'
      @tournaments = Tournament.order(:name)
      @seasons = Season.order(start_year: :desc)
      @auctions = Auction.unscoped
                         .public_send(@status)
                         .includes(:auction_rounds, :transfers, league: %i[tournament season division])
                         .references(:leagues)
                         .order('auctions.created_at DESC')
      @auctions = @auctions.where('leagues.name LIKE ?', "%#{params[:query]}%") if params[:query].present?
      @auctions = @auctions.where(leagues: { tournament_id: params[:tournament_id] }) if params[:tournament_id].present?
      @auctions = @auctions.where(leagues: { season_id: params[:season_id] }) if params[:season_id].present?
      @auctions = @auctions.page(params[:page]).per(PER_PAGE)
    end
  end
end
