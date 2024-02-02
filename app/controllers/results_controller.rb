class ResultsController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  helper_method :league

  layout 'react_application'

  # TODO: check def's

  def index; end

  private

  def league
    @league ||= League.find(params[:league_id])
  end
end
