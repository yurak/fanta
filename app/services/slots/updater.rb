require 'csv'

module Slots
  class Updater < ApplicationService
    def call
      csv.each do |slot_data|
        slot = Slot.find_by(id: slot_data[0])
        next unless slot

        slot.update(location: slot_data[1])
      end
    end

    private

    def csv
      csv_text = File.read(file_path)
      CSV.parse(csv_text, headers: false)
    end

    def file_path
      Rails.root.join('config/mantra/slots_location.csv')
    end
  end
end
