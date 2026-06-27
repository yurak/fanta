class ResultsController < ApplicationController
  respond_to :html

  helper_method :league

  layout 'react_application'

  def index; end

  private

  def league
    @league ||= League.find(params.expect(:league_id))
  end
end
