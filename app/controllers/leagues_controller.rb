class LeaguesController < ApplicationController
  respond_to :html

  helper_method :league

  # Specify the layout for the index action
  layout 'react_application', only: [:index]

  def index; end

  def show; end

  private

  def league
    @league ||= League.find(params.expect(:id))
  end
end
