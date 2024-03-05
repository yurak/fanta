module TelegramBot
  class PlayerSoldNotifier < ApplicationService
    attr_reader :player, :team

    def initialize(player, team)
      @player = player
      @team = team
    end

    def call
      return false unless team
      return false unless player

      TelegramBot::Sender.call(team.user, message)
      true
    end

    private

    def message
      "#{tournament.icon} #{team.human_name} player #{player.full_name} left #{tournament.name} tournament.\n" \
        'You will be able to replace him at the next auction.'
    end

    def tournament
      @tournament ||= team.league.tournament
    end
  end
end
