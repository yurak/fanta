class ResultsController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  helper_method :league

  def index
    @results = league.tournament.fanta? ? ordered_national_results : league_results.ordered
  end

  private

  def ordered_national_results
    case order_params[:order]
    when 'points'
      league_results.order(points: :desc)
    when 'gamedays'
      league_results.order(wins: :desc)
    when 'lineup'
      league_results.sort_by(&:league_best_lineup).reverse
    else
      league_results.order(total_score: :desc)
    end
  end

  def order_params
    params.permit(:order)
  end

  def league
    @league ||= League.find(params[:league_id])
  end

  def league_results
    @league_results ||= league.results
  end
end
