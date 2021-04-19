module Positions
  class Creator < ApplicationService
    def call
      positions.each do |name|
        Position.find_or_create_by(name: name)
      end
    end

    private

    def positions
      YAML.load_file(Rails.root.join('config/mantra/positions.yml'))['positions']
    end
  end
end
