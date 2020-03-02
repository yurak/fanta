module TeamLineups
  class Creator
    attr_reader :params, :team, :lineup

    delegate :errors, :players, to: :lineup

    AMOUNT = 11
    RESERVED = 7

    def initialize(team:, params:)
      @team   = team
      @params = params.merge(player_ids: @team.players.ids[0..17])
      @lineup = team.lineups.new(@params)
    end

    def call
      errors.add(:base, "#{team.name.titleize} lineup already exist, to change the module - go to the update page") if lineup_exist?
      errors.add(:base, "Team should have #{full_squad} players") if players.size != full_squad
      lineup.tour_id = active_tour&.id
      lineup.save if errors.empty?
    end

    private

    def lineup_exist?
      active_tour.lineups.find_by(team: team)
    end

    def full_squad
      AMOUNT + RESERVED
    end

    def active_tour
      # TODO: specify for League tours
      Tour.set_lineup.first
    end
  end
end
