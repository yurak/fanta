module Manage
  class LeaguesController < Manage::BaseController
    STATUSES = %w[initial active archived].freeze

    def index
      @status = STATUSES.include?(params[:status]) ? params[:status] : 'initial'
      @tournaments = Tournament.order(:name)
      @seasons = Season.order(start_year: :desc)
      @leagues = League.public_send(@status)
                       .includes(:division, :tournament, :season, :results, :tours)
                       .order(season_id: :desc, created_at: :desc)
      @leagues = @leagues.where('leagues.name LIKE ?', "%#{params[:query]}%") if params[:query].present?
      @leagues = @leagues.where(tournament_id: params[:tournament_id]) if params[:tournament_id].present?
      @leagues = @leagues.where(season_id: params[:season_id]) if params[:season_id].present?
      @leagues = @leagues.page(params[:page]).per(PER_PAGE)
    end

    def show
      @teams = league.teams.includes(user: :user_profile).order(:human_name)
      @auctions = league.auctions.includes(:auction_rounds).order(:number)
      @results = league.results.ordered.includes(:user_title, team: { user: :user_profile })
    end

    def new
      @league = League.new
    end

    def edit
      league
    end

    def create
      @league = League.new(league_params)
      if @league.save
        redirect_to manage_leagues_path, notice: t('manage.leagues.created')
      else
        render :new
      end
    end

    def update
      if league.update(league_params)
        redirect_to manage_leagues_path, notice: t('manage.leagues.updated')
      else
        render :edit
      end
    end

    def activate
      if league.fanta?
        Leagues::FantaActivator.call(league.id)
      else
        Leagues::Activator.call(league.id, Time.zone.parse(params[:deadline]))
      end
      redirect_to manage_leagues_path, notice: t('manage.leagues.activated')
    end

    def archive
      league.archived!
      redirect_to manage_league_path(league), notice: t('manage.leagues.archived')
    end

    def crown
      result = league.results.find(params[:result_id])
      ActiveRecord::Base.transaction { assign_title(result) }
      redirect_to manage_league_path(league), notice: t('manage.leagues.crowned')
    end

    private

    def league
      @league ||= League.find(params[:id])
    end

    def assign_title(result)
      user = result.team.user
      result.update!(title: true)
      UserTitle.create!(
        user: user,
        tournament: league.tournament,
        result: result,
        team_name: result.team.human_name,
        season: "#{league.season.start_year}/#{league.season.end_year}",
        championship_number: UserTitle.maximum(:championship_number).to_i + 1
      )
      return if user.champion_number.present?

      user.update!(champion_number: User.maximum(:champion_number).to_i + 1)
    end

    def league_params
      params.require(:league).permit(
        :name, :tournament_id, :season_id, :division_id,
        :auction_type, :auction_number, :auction_step, :tour_difference, :demo,
        :min_avg_def_score, :max_avg_def_score, :open_for_join, :join_code, :default_for_join
      )
    end
  end
end
