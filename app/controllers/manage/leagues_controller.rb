module Manage
  class LeaguesController < Manage::BaseController
    STATUSES = %w[initial active archived].freeze

    def index
      @status = STATUSES.include?(params[:status]) ? params[:status] : 'initial'
      @leagues = League.public_send(@status).includes(:tournament, :season).order(created_at: :desc)
    end

    def new
      @league = League.new
    end

    def edit; end

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
      deadline = Time.zone.parse(params[:deadline])
      Leagues::Activator.call(league.id, deadline)
      redirect_to manage_leagues_path, notice: t('manage.leagues.activated')
    end

    private

    def league
      @league ||= League.find(params[:id])
    end

    def league_params
      params.require(:league).permit(
        :name, :tournament_id, :season_id, :division_id,
        :auction_type, :auction_number, :auction_step, :tour_difference
      )
    end
  end
end
