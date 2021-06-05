module Players
  class Manager < ApplicationService
    def initialize(player_hash)
      @player_hash = player_hash
      @id = player_hash['id']
    end

    def call
      return false unless club || national_team

      if @id
        player = Player.find(@id)

        player.update(player_data)
      else
        return false if positions_arr.blank?

        player = Player.new(player_data)
        player.positions << Position.where(name: positions_arr)

        return false unless player.valid?

        player.save
      end
    end

    private

    def base_data
      @player_hash.slice('first_name', 'name', 'nationality', 'tm_url')
    end

    def player_data
      data = national_team ? base_data.merge(national_team_id: national_team.id) : base_data
      data.merge(club_id: club_id)
    end

    def club_id
      club ? club.id : base_club.id
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

    def base_club
      Club.find_by(name: 'xxx')
    end

    def national_team?
      @player_hash['national_team']
    end

    def national_team
      return false unless national_team?

      NationalTeam.find_by(code: @player_hash['nationality'])
    end
  end
end
