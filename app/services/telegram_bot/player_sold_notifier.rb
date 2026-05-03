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

      TelegramBot::Sender.call(team.user, message(team))
      true
    end

    private

    def message(team)
      I18n.t(
        'telegram.notifier.player.left',
        locale: locale(team),
        icon: tournament.icon,
        player_name: player.full_name,
        team_name: team.human_name,
        tournament_name: tournament.name,
        code: tournament.code
      )
    end

    def tournament
      @tournament ||= team.league.tournament
    end

    def locale(team)
      return :en unless team.user

      team.user.locale.to_sym
    end
  end
end
