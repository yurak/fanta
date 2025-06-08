class LeaguesController < ApplicationController
  respond_to :html

  helper_method :league

  # Specify the layout for the index action
  layout 'react_application', only: [:index]

  def index; end

  def show; end

  def activate
    Leagues::Activator.call(league.id) if can? :activate, League

    redirect_to league_path(league)
  end

  private

  def league
    @league ||= League.find(params[:id])
  end
end
