module TelegramBot
  class PlayerSoldNotifier < ApplicationService
    include TelegramBot::HtmlMessage
    include TelegramBot::Recipient

    attr_reader :player, :team

    def initialize(player, team)
      @player = player
      @team = team
    end

    def call
      return false unless team
      return false unless player

      send_html(team.user, message(team))
      true
    end

    private

    def message(team)
      html_message(
        'telegram.notifier.player.left',
        locale: locale,
        icon: tournament.icon,
        player_name: player.full_name,
        team_name: team.human_name,
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
