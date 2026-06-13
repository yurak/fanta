class RoundPlayersController < ApplicationController
  layout 'react_application', only: %i[index]

  helper_method :league

  # The round players stats page is rendered by the React app (see
  # app/client/pages/RoundPlayers). Data is served by Api::RoundPlayersController.
  def index; end

  private

  def league
    return @league if defined?(@league)

    @league = League.find_by(id: params[:league])
  end
end
