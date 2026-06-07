class RoundPlayersController < ApplicationController
  layout 'react_application', only: %i[index]

  # The round players stats page is rendered by the React app (see
  # app/client/pages/RoundPlayers). Data is served by Api::RoundPlayersController.
  def index; end
end
