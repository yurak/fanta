module Manage
  class ClubsController < BaseController
    def index
      @clubs = Club.includes(:tournament).order(id: :desc)
      @clubs = @clubs.where('name LIKE ?', "%#{params[:name]}%") if params[:name].present?
      @clubs = @clubs.page(params[:page]).per(PER_PAGE)
    end

    def show
      @club = Club.includes(:tournament, :ec_tournament).find(params.expect(:id))
      @players_count = @club.players.count
      @players = @club.players.order(id: :desc).limit(50)
    end
  end
end
