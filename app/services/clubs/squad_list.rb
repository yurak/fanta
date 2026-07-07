module Clubs
  class SquadList < ApplicationService
    def initialize(club)
      @club = club
    end

    def call
      tm_ids = squad_tm_ids
      existing = Player.where(tm_id: tm_ids).includes(:positions).index_by { |p| p.tm_id.to_s }
      entries = tm_ids.map { |tm_id| entry(tm_id, existing[tm_id]) }
      present, absent = entries.partition { |e| e[:player] }
      present + absent
    end

    private

    def squad_tm_ids
      tm_club_id = @club.tm_url.to_s[%r{/verein/(\d+)}, 1]
      Players::Transfermarkt::ClubSquadParser.call(tm_club_id)
    end

    def entry(tm_id, player)
      player ? existing_entry(tm_id, player) : new_entry(tm_id, fetch_tm_data(tm_id))
    end

    def existing_entry(tm_id, player)
      {
        tm_id: tm_id, player: player, name: player.full_name,
        position: player.positions.map(&:name).join(', ').presence,
        price: player.tm_price, nationality: player.nationality, birth_date: player.birth_date.presence
      }
    end

    def new_entry(tm_id, data)
      {
        tm_id: tm_id, player: nil,
        name: data && [data[:first_name], data[:name]].compact_blank.join(' ').presence,
        position: data && [data[:tm_pos1], data[:tm_pos2], data[:tm_pos3]].compact_blank.join(', ').presence,
        price: data && data[:tm_price], nationality: data && data[:nationality], birth_date: data && data[:birth_date]
      }
    end

    def fetch_tm_data(tm_id)
      Players::Transfermarkt::ApiParser.call(tm_id, position_skip: true)
    rescue StandardError
      nil
    end
  end
end
