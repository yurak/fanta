module Clubs
  class SquadList < ApplicationService
    def initialize(club)
      @club = club
    end

    def call
      tm_ids = squad_tm_ids
      { squad: build_squad(tm_ids), missing: missing_players(tm_ids) }
    end

    private

    def build_squad(tm_ids)
      existing = Player.where(tm_id: tm_ids).includes(:positions).index_by { |p| p.tm_id.to_s }
      entries = tm_ids.map { |tm_id| entry(tm_id, existing[tm_id]) }
      present, absent = entries.partition { |e| e[:player] }
      present + absent
    end

    def missing_players(tm_ids)
      ids = tm_ids.map(&:to_s)
      @club.players.includes(:positions).order(:name)
           .reject { |player| player.tm_id.present? && ids.include?(player.tm_id.to_s) }
           .map { |player| { player: player, current_tm_club: current_tm_club(player) } }
    end

    def current_tm_club(player)
      return nil if player.tm_id.blank?

      latest_completed_transfer(player.tm_id)&.dig(:new_club_name)
    rescue StandardError
      nil
    end

    def latest_completed_transfer(tm_id)
      completed = Players::Transfermarkt::TransferHistoryParser.call(tm_id).select { |t| completed_transfer?(t) }
      completed.max_by { |t| [t[:start_date], t[:tm_transfer_id].to_i] }
    end

    def completed_transfer?(transfer)
      !transfer[:upcoming] && transfer[:start_date] && transfer[:start_date] <= Time.zone.today
    end

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
