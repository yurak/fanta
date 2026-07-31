module Manage
  class AuctionsController < Manage::BaseController
    STATUSES = %w[initial sales blind_bids live closed].freeze

    DEADLINE_ORDER = <<~SQL.squish
      COALESCE(
        (SELECT ar.deadline FROM auction_rounds ar WHERE ar.auction_id = auctions.id
          ORDER BY ar.number DESC LIMIT 1),
        auctions.deadline
      ) ASC NULLS LAST, auctions.created_at DESC
    SQL

    def index
      @status = STATUSES.include?(params[:status]) ? params[:status] : 'initial'
      @tournaments = Tournament.order(:name)
      @seasons = Season.order(start_year: :desc)
      @auctions = Auction.unscoped
                         .public_send(@status)
                         .joins(:league)
                         .includes(:auction_rounds, :transfers, league: %i[tournament season division])
                         .order(Arel.sql(DEADLINE_ORDER))
      @auctions = @auctions.where('leagues.name LIKE ?', "%#{params[:query]}%") if params[:query].present?
      @auctions = @auctions.where(leagues: { tournament_id: params[:tournament_id] }) if params[:tournament_id].present?
      @auctions = @auctions.where(leagues: { season_id: params[:season_id] }) if params[:season_id].present?
      @auctions = @auctions.page(params[:page]).per(PER_PAGE)
    end
  end
end
