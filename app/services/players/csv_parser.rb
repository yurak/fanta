require 'csv'

module Players
  class CsvParser < ApplicationService
    def initialize(file_name)
      @file_name = file_name
    end

    def call
      return unless file_exist?

      csv.each do |player_data|
        Players::Manager.call(player_data.to_hash)
      end
    end

    private

    def csv
      csv_text = File.read(file_path)
      CSV.parse(csv_text, headers: true)
    end

    def file_exist?
      File.exist?(file_path)
    end

    def file_path
      Rails.root.join('config', 'mantra', 'players_lists', "#{@file_name}.csv")
    end
  end
end
