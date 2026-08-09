module Manage
  class ClubsController < BaseController
    def index
      @tournaments = Tournament.order(:name)
      @clubs = Club.includes(:tournament).order(:name)
      @clubs = @clubs.where('name ILIKE ?', "%#{params[:name]}%") if params[:name].present?
      @clubs = @clubs.where('tournament_id = :id OR ec_tournament_id = :id', id: params[:tournament_id]) if params[:tournament_id].present?
      @clubs = @clubs.where(status: params[:status]) if Club.statuses.key?(params[:status])
      @clubs = @clubs.page(params[:page]).per(PER_PAGE)
    end

    def show
      @club = Club.includes(:tournament, :ec_tournament).find(params.expect(:id))
      @players_count = @club.players.count
      @players = @club.players.includes(:positions).order(id: :desc).limit(50)
    end

    def sync_squad
      @club = Club.find(params.expect(:id))
      result = Clubs::SquadList.call(@club)
      @squad = result[:squad]
      @missing = result[:missing]
    rescue Players::Transfermarkt::ApiError => e
      redirect_to manage_club_path(@club),
                  alert: t('manage.clubs.tm_unavailable', error: e.http_code || e.message)
    end

    def create_players
      club = Club.find(params.expect(:id))
      created = Clubs::PlayersCreator.call(params[:tm_ids])

      redirect_to manage_club_path(club), notice: t('manage.clubs.players_created', count: created)
    end
  end
end
