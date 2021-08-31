module Tournaments
  class Creator < ApplicationService
    def call
      tournaments.each do |code, params|
        Tournament.create(name: params['name'], code: code, eurocup: params['eurocup'])
      end
    end

    private

    def tournaments
      YAML.load_file(Rails.root.join('config/mantra/tournaments.yml'))
    end
  end
end
