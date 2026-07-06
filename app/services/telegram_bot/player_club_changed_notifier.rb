module TelegramBot
  class PlayerClubChangedNotifier < ApplicationService
    attr_reader :player, :team, :new_club

    def initialize(player, team, new_club)
      @player = player
      @team = team
      @new_club = new_club
    end

    def call
      return false unless team
      return false unless player
      return false unless new_club

      TelegramBot::Sender.call(team.user, message)
      true
    end

    private

    def message
      I18n.t(
        'telegram.notifier.player.club_changed',
        locale: locale,
        icon: tournament.icon,
        player_name: player.full_name,
        team_name: team.human_name,
        new_club_name: new_club.name,
        tournament_name: tournament.name,
        code: tournament.code
      )
    end

    def tournament
      @tournament ||= team.league.tournament
    end

    def locale
      return :en unless team.user

      team.user.locale.to_sym
    end
  end
end
