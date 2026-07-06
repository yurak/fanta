module Manage
  class ClubsController < BaseController
    def index
      @clubs = Club.includes(:tournament).order(id: :desc)
      @clubs = @clubs.where('name ILIKE ?', "%#{params[:name]}%") if params[:name].present?
      @clubs = @clubs.page(params[:page]).per(PER_PAGE)
    end

    def show
      @club = Club.includes(:tournament, :ec_tournament).find(params.expect(:id))
      @players_count = @club.players.count
      @players = @club.players.order(id: :desc).limit(50)
    end

    def sync_squad
      @club = Club.find(params.expect(:id))
      @squad = Clubs::SquadList.call(@club)
    end

    def create_players
      club = Club.find(params.expect(:id))
      created = Clubs::PlayersCreator.call(params[:tm_ids])

      redirect_to manage_club_path(club), notice: t('manage.clubs.players_created', count: created)
    end
  end
end
