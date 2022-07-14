require 'csv'
require 'open-uri'

module Players
  class CsvParser < ApplicationService
    def initialize(file_url = nil, file_name = nil)
      @file_name = file_name
      @file_url = file_url
    end

    def call
      return false if @file_name && !file_exist?
      return false unless csv

      csv.each do |player_data|
        Players::Manager.call(player_data.to_hash)
      end
    end

    private

    def csv
      csv_text = URI.parse(@file_url).open.read if @file_url
      csv_text = File.read(file_path) if @file_name

      return unless csv_text

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
