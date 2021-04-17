class PositionCreator < ApplicationService
  def call
    positions.each do |name|
      Position.create(name: name)
    end
  end

  private

  def positions
    YAML.load_file(Rails.root.join('config/mantra/positions.yml'))['positions']
  end
end
