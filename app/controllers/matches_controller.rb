class MatchesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  helper_method :match

  respond_to :html

  def show; end

  def autobot
    @match ||= Match.find(params[:match_id])

    @match.autobot

    redirect_to match_path(@match)
  end

  private

  def match
    @match ||= Match.find(params[:id])
  end
end
