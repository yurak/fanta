module Manage
  class ChampionsController < BaseController
    def index
      @champions = User.champions.includes(user_titles: [:tournament, { result: :league }])
    end
  end
end
