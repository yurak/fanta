module Manage
  class ChampionsController < BaseController
    TABS = %w[list matrix].freeze

    def index
      @tab = TABS.include?(params[:tab]) ? params[:tab] : TABS.first
      @champions = User.champions.includes(user_titles: [:tournament, { result: :league }])
      @matrix = Manage::ChampionsMatrix.new(@champions) if @tab == 'matrix'
    end
  end
end
