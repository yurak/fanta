require 'csv'

module Players
  class CsvManager < ApplicationService
    def initialize(file_name)
      @file_name = file_name
    end

    def call
      return unless file_exist?

      csv.each do |player_data|
        if player_data['id']
          # player = Player.find(player_data['id'])
          #
          # player.update(player_hash(player_data))
        else
          p 'create'
          player = Player.new(player_hash(player_data))
          player.positions << Position.where(name: positions_arr(player_data))
          player.club = Club.find_by(name: player_data['club'])
          # player.save

          p positions_arr(player_data.to_hash)
          # p player_data.to_hash
        end
      end
    end

    private

    def player_hash(player_data)
      player_data.to_hash.slice('first_name', 'name', 'nationality', 'tm_url')
    end

    def positions_arr(player_data)
      [player_data['position1'], player_data['position2'], player_data['position3']].compact
    end

    def csv
      csv_text = File.read(file_path)
      CSV.parse(csv_text, :headers => true)
    end

    def file_exist?
      File.exist?(file_path)
    end

    def file_path
      Rails.root.join('config', 'mantra', 'players_lists', "#{@file_name}.csv")
    end
  end
end
