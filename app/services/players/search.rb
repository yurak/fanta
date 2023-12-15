module Players
  class Search < ApplicationService
    attr_reader :club_id, :league_id, :name, :position, :tournament_id

    def initialize(params)
      @club_id = params[:club_id]
      @league_id = params[:league_id]
      @name = params[:name]
      @position = params[:position]
      @tournament_id = params[:tournament_id]
    end

    def call
      players = Player.by_tournament(tournament)
                      .by_club(club_id)
                      .by_classic_position(position)
      players = Player.where(id: players.pluck(:id).uniq).search_by_name(name) if name
      players
    end

    private

    def tournament
      tournament_id = league ? league.tournament_id : @tournament_id

      Tournament.find_by(id: tournament_id)
    end

    def league
      League.find_by(id: league_id)
    end
  end
end
