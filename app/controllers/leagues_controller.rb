class LeaguesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  respond_to :html

  helper_method :league

  def index; end

  def show; end

  private

  def league
    @league ||= League.find(params[:id])
  end
end
