module TeamLineups
  class Creator
    attr_reader :params, :team, :lineup

    delegate :errors, :players, to: :lineup

    AMOUNT = 11
    RESERVED = 7

    def initialize(team:, params:)
      @params = params
      @team   = team
      @lineup = team.lineups.new(params)
    end

    def call
      errors.add(:base, "Team should have at least #{AMOUNT} players") if players.size < AMOUNT
      errors.add(:base, "Max amount is  #{AMOUNT + RESERVED} players") if players.size > AMOUNT + RESERVED
      lineup.tour_id = active_tour&.id
      lineup.save if errors.empty?
    end

    private

    def active_tour
      Tour.set_lineup.first
    end
  end
end
