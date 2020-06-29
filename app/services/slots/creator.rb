module Slots
  class Creator < ApplicationService
    def call
      team_modules.each do |module_name, slot_hash|
        tm = TeamModule.new(name: module_name)
        slot_hash.each do |number, positions|
          tm.slots << Slot.new(number: number, position: positions.join('/'))
        end
        tm.save
      end
    end

    private

    def team_modules
      YAML.load_file(Rails.root.join('config', 'mantra', 'team_modules.yml'))
    end
  end
end
