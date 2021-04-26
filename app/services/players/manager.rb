module Players
  class Manager < ApplicationService
    def initialize(player_hash)
      @player_hash = player_hash
      @id = player_hash['id']
    end

    def call
      return false unless club

      if @id
        player = Player.find(@id)

        player.update(base_data.merge(club_id: club.id))
      else
        return false if positions_arr.blank?

        player = Player.new(base_data)
        player.positions << Position.where(name: positions_arr)
        player.club = club

        return false unless player.valid?

        player.save
      end
    end

    private

    def base_data
      @player_hash.slice('first_name', 'name', 'nationality', 'tm_url')
    end

    def positions_arr
      [
        @player_hash['position1'],
        @player_hash['position2'],
        @player_hash['position3']
      ].compact
    end

    def club
      Club.find_by(name: @player_hash['club_name'])
    end
  end
end
