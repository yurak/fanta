module Clubs
  class PlayersCreator < ApplicationService
    def initialize(tm_ids)
      @tm_ids = Array(tm_ids).compact_blank
    end

    def call
      @tm_ids.count { |tm_id| create_player(tm_id) }
    end

    private

    def create_player(tm_id)
      return false if Player.exists?(tm_id: tm_id)

      data = Players::Transfermarkt::ApiParser.call(tm_id)
      return false unless data

      Players::Manager.call(data.stringify_keys)
    rescue StandardError => e
      Rails.logger.warn("Squad create failed for tm_id=#{tm_id}: #{e.message}")
      false
    end
  end
end
