class MatchesController < ApplicationController
  helper_method :match

  respond_to :html

  def show
    redirect_to leagues_path unless match
  end

  def autobot
    match.autobot

    redirect_to match_path(match)
  end

  private

  def match
    @match ||= Match.find_by(id: params[:id] || params[:match_id])
  end
end
