module Slots
  class Creator < ApplicationService
    def call
      return false if team_modules.empty?

      team_modules.each do |module_name, slot_hash|
        next if TeamModule.find_by(name: module_name)

        tm = TeamModule.new(name: module_name)
        slot_hash.each do |number, positions|
          tm.slots << Slot.new(number: number, position: positions.join('/'))
        end
        tm.save
      end
    end

    private

    def team_modules
      YAML.load_file(Rails.root.join('config/mantra/team_modules.yml'))
    end
  end
end
