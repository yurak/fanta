module Standings
  class FotmobParser < ApplicationService
    LEAGUE_URL = 'https://www.fotmob.com/leagues'.freeze
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
                 '(KHTML, like Gecko) Chrome/124.0 Safari/537.36'.freeze
    REQUEST_TIMEOUT = 25

    attr_reader :tournament

    def initialize(tournament)
      @tournament = tournament
    end

    def call
      return [] if tournament&.source_id.blank?

      rows.filter_map { |row| entry(row) }
    end

    private

    def entry(row)
      position = row['idx']
      return nil if position.blank?

      goals_for, goals_against = split_scores(row['scoresStr'])
      {
        position: position.to_i, fotmob_team_id: row['id'].presence&.to_i,
        team_name: row['name'].to_s, played: row['played'].to_i,
        wins: row['wins'].to_i, draws: row['draws'].to_i, losses: row['losses'].to_i,
        goals_for: goals_for, goals_against: goals_against,
        points: row['pts'].to_i, zone_color: row['qualColor'].to_s
      }
    end

    def split_scores(str)
      scored, conceded = str.to_s.split('-')
      [scored.to_i, conceded.to_i]
    end

    def rows
      tables = page_props&.dig('table')
      data = tables.is_a?(Array) ? tables.first&.dig('data') : nil
      return [] if data.blank?

      single_table(data) || composite_table(data) || []
    end

    def single_table(data)
      table = data['table']
      table.is_a?(Hash) ? table['all'] : nil
    end

    def composite_table(data)
      groups = data['tables']
      return nil if groups.blank?

      groups.filter_map { |group| group.dig('table', 'all') }.max_by(&:size)
    end

    def page_props
      @page_props ||= JSON.parse(Nokogiri::HTML(html).css('#__NEXT_DATA__').text)['props']['pageProps']
    rescue JSON::ParserError, NoMethodError => e
      Rails.logger.warn("[standings] FotMob parse failed for tournament #{tournament.id}: #{e.message}")
      nil
    end

    def html
      RestClient::Request.execute(method: :get, url: "#{LEAGUE_URL}/#{tournament.source_id}/table",
                                  headers: { user_agent: USER_AGENT }, timeout: REQUEST_TIMEOUT)
    rescue RestClient::Exception, SocketError, OpenSSL::SSL::SSLError => e
      Rails.logger.warn("[standings] FotMob fetch failed for tournament #{tournament.id}: #{e.class}")
      ''
    end
  end
end
