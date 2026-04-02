module Manage
  class PlayersController < BaseController
    def index; end

    def create
      result = parse_player_hash(params[:player_hash])

      if result.nil?
        redirect_to manage_players_path, alert: t('manage.players.invalid_hash')
        return
      end

      if Players::Manager.call(result)
        redirect_to manage_players_path, notice: t('manage.players.created')
      else
        redirect_to manage_players_path, alert: t('manage.players.failed')
      end
    end

    private

    def parse_player_hash(raw)
      return nil if raw.blank?

      json_str = raw.strip.gsub('=>', ':').gsub(/\bnil\b/, 'null')
      JSON.parse(json_str)
    rescue JSON::ParserError
      nil
    end
  end
end
