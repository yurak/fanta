module Manage
  class ChampionsController < BaseController
    def index
      @champions = User.champions.includes(user_titles: :tournament)
    end
  end
end
