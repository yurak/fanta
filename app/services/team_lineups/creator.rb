module TeamLineups
  class Creator
    attr_reader :params, :team, :lineup

    delegate :errors, :players, to: :lineup

    AMOUNT = 11
    RESERVED = 7

    def initialize(team:, params:)
      @team   = team
      @params = params
      @lineup = team.lineups.new(@params)
    end

    def call
      errors.add(:base, "#{team.human_name} lineup already exist, to change the module - go to Edit Module page") if lineup_exist?
      lineup.tour_id = active_tour&.id
      generate_match_players
      generate_reserve_players
      lineup.save if errors.empty?
    end

    private

    def generate_match_players
      lineup.team_module.slots.each do |slot|
        real_position = slot.position
        main_positions = real_position.split('/')
        player = lineup.team.players.by_position(main_positions).where.not(id: used_players_ids).first
        unless player
          available_positions = main_positions.map { |p| Position::DEPENDENCY[p] }.flatten.uniq
          player = lineup.team.players.by_position(available_positions).where.not(id: used_players_ids).first
        end
        round_player = RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: player)

        lineup.match_players.new(round_player: round_player, real_position: real_position)
        used_players_ids << player.id
      end
    end

    def generate_reserve_players
      lineup.team.players.where.not(id: used_players_ids).limit(RESERVED).each do |player|
        round_player = RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: player)
        lineup.match_players.new(round_player: round_player)
      end
    end

    def used_players_ids
      @used_players_ids ||= []
    end

    def lineup_exist?
      active_tour.lineups.find_by(team: team)
    end

    def tournament_round
      active_tour.tournament_round
    end

    def active_tour
      team.league.tours.set_lineup.first
    end
  end
end
