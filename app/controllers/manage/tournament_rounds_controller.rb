module Manage
  class TournamentRoundsController < BaseController
    def index
      @dashboard = Tours::Dashboard.call
    end
  end
end
