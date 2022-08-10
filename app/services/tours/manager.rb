module Tours
  class Manager < ApplicationService
    CLOSED_STATUS = 'closed'.freeze
    LOCKED_STATUS = 'locked'.freeze
    POSTPONED_STATUS = 'postponed'.freeze
    SET_LINEUP_STATUS = 'set_lineup'.freeze

    attr_reader :tour, :status

    def initialize(tour, status)
      @tour = tour
      @status = status
    end

    def call
      set_lineup

      lock

      postpone

      close
    end

    private

    def set_lineup
      return if status != SET_LINEUP_STATUS

      tour.set_lineup! if RoundPlayers::Creator.call(tour.tournament_round.id)
      notify_tg_opened_tour
    end

    def lock
      return unless tour.set_lineup? && status == LOCKED_STATUS

      clone_missed_lineups if tour.mantra?
      generate_not_in_squad_players if tour.mantra?

      tour.locked!
    end

    def postpone
      tour.postponed! if tour.locked? && status == POSTPONED_STATUS
    end

    def close
      return unless tour.locked_or_postponed? && status == CLOSED_STATUS && tour.tournament_round.finished?

      Tour.transaction do
        tour.closed!
        update_results
        Lineups::Updater.call(tour)
        RoundPlayers::Updater.call(tour.tournament_round)
      end
    end

    def update_results
      tour.fanta? ? Results::NationalUpdater.call(tour) : Results::Updater.call(tour)
    end

    def clone_missed_lineups
      tour.teams.each do |team|
        next if tour.lineups.by_team(team.id).any?

        Lineups::Cloner.call(team, tour)
      end
    end

    def generate_not_in_squad_players
      tour.lineups.each do |lineup|
        lineup.team.players_not_in(lineup).each do |round_player|
          MatchPlayer.create(lineup: lineup, round_player: round_player, subs_status: :not_in_squad)
        end
      end
    end

    def notify_tg_opened_tour
      TelegramBot::OpenedTourNotifier.call(tour)
    end
  end
end
