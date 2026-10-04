module TelegramBot
  class PlayerClubChangedNotifier < ApplicationService
    include TelegramBot::HtmlMessage
    include TelegramBot::Recipient

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

      send_html(team.user, message)
      true
    end

    private

    def message
      html_message(
        'telegram.notifier.player.club_changed',
        locale: locale,
        icon: tournament.icon,
        player_name: player.full_name,
        team_name: team.human_name,
        old_club_name: player.club&.name,
        new_club_name: new_club.name,
        tournament_name: tournament.name,
        url: Rails.application.routes.url_helpers.player_url(player),
        code: tournament.code
      )
    end

    def tournament
      @tournament ||= team.league.tournament
    end

    def user
      @user ||= team.user
    end
  end
end
