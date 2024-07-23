module PlayerPositions
  class Updater < ApplicationService
    attr_reader :player

    def initialize(player)
      @player = player
    end

    def call
      return false unless player
      return unless tm_positions.any?

      pos = player.player_positions.map { |pp| Slot::POS_MAPPING[pp.position.name] }

      legacy_positions = pos - tm_positions
      new_positions = tm_positions - pos

      legacy_positions.each do |pos_name|
        player_position = player.player_positions.find_by(position_id: position(pos_name))
        player_position.audit_comment = pos_name
        player_position.destroy
      end

      new_positions.each do |pos_name|
        player.player_positions.create!(position_id: position(pos_name).id, audit_comment: pos_name)
      end

      tm_positions.compact.sort
    end

    private

    def tm_positions
      @tm_positions ||= Players::Transfermarkt::PositionMapper.call(player, year)
    end

    def position(pos_name)
      Position.find_by(human_name: pos_name)
    end

    def year
      @year ||= Season.last.start_year
    end
  end
end
