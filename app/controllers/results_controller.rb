class ResultsController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  helper_method :league

  def index
    @results = league.tournament.fanta? ? ordered_national_results : league.results.ordered
  end

  private

  def ordered_national_results
    case order_params[:order]
    when 'points'
      league.results.order(points: :desc)
    when 'gamedays'
      league.results.order(wins: :desc)
    when 'lineup'
      league.results.sort_by(&:league_best_lineup).reverse
    else
      league.results.order(total_score: :desc)
    end
  end

  def order_params
    params.permit(:order)
  end

  def league
    @league ||= League.find(params[:league_id])
  end
end
