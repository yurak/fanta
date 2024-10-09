class MatchesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  helper_method :match

  respond_to :html

  def show
    redirect_to leagues_path unless match
  end

  def autobot
    @match ||= Match.find(params[:match_id])

    @match.autobot

    redirect_to match_path(@match)
  end

  private

  def match
    @match ||= Match.find_by(id: params[:id])
  end
end
