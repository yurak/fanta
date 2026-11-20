module Manage
  class LeagueTeamPlacer < ApplicationService
    Plan = Struct.new(:action, :user, :team, :source, :error, keyword_init: true) do
      def ok? = error.nil?
      def move? = action == :move
      def copy? = action == :copy
    end

    attr_reader :league, :user_id

    def initialize(league, user_id)
      @league = league
      @user_id = user_id.to_s.strip
    end

    def call
      plan = self.class.new(league, user_id).plan
      return plan unless plan.ok?

      plan.move? ? move(plan) : copy(plan)
      plan
    end

    def plan
      return failure(:user_not_found) if user.nil?
      return failure(:already_in_league, team: existing_in_league) if existing_in_league

      return move_plan if in_tournament
      return failure(:nothing_to_copy) if source_elsewhere.nil?

      Plan.new(action: :copy, user: user, source: source_elsewhere)
    end

    private

    def failure(error, **attrs)
      Plan.new(action: :none, user: user, error: error, **attrs)
    end

    def move_plan
      return failure(:source_league_active, source: in_tournament) if in_tournament.league&.active?

      Plan.new(action: :move, user: user, source: in_tournament)
    end

    def move(plan)
      plan.source.update!(league_id: league.id, tournament_id: league.tournament_id)
      plan.team = plan.source
    end

    def copy(plan)
      source = plan.source
      plan.team = Team.create!(
        user_id: user.id, league_id: league.id, tournament_id: league.tournament_id,
        name: Team.generate_name(source.human_name, user.id, league.tournament), code: source.code,
        human_name: source.human_name, logo_url: source.logo_url,
        budget: Team::DEFAULT_BUDGET, transfer_slots: 0
      )
    end

    def user
      return @user if defined?(@user)

      @user = user_id.match?(/\A\d+\z/) ? User.find_by(id: user_id) : nil
    end

    def existing_in_league
      return @existing_in_league if defined?(@existing_in_league)

      @existing_in_league = teams.find { |team| team.league_id == league.id }
    end

    def in_tournament
      return @in_tournament if defined?(@in_tournament)

      @in_tournament = teams.select { |team| team.league&.tournament_id == league.tournament_id }.max_by(&:id)
    end

    def source_elsewhere
      @source_elsewhere ||= most_used_identity&.max_by(&:id)
    end

    def most_used_identity
      teams.group_by { |team| [team.human_name, team.code] }
           .values
           .max_by { |group| [group.size, group.map(&:id).max] }
    end

    def teams
      @teams ||= user ? Team.where(user_id: user.id).includes(:league).to_a : []
    end
  end
end
