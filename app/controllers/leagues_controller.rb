class LeaguesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  respond_to :html

  helper_method :league, :leagues

  def index; end

  def show; end

  private

  def league
    @league ||= League.find(params[:id])
  end

  def leagues
    League.active.or(League.archived).includes(:results).order('season_id DESC, tournament_id ASC')
          .order(Arel.sql('CASE WHEN division_id IS NULL THEN 1 ELSE 0 END, division_id ASC'))
  end
end
