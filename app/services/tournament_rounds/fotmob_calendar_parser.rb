module TournamentRounds
  class FotmobCalendarParser < ApplicationService
    LEAGUE_URL = 'https://www.fotmob.com/leagues'.freeze
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
                 '(KHTML, like Gecko) Chrome/124.0 Safari/537.36'.freeze
    REQUEST_TIMEOUT = 25
    MAX_REDIRECTS = 3

    attr_reader :tournament

    def initialize(tournament)
      @tournament = tournament
    end

    def call
      return [] if tournament&.source_id.blank?

      all_matches.filter_map { |match_data| entry(match_data) }
    end

    private

    def entry(match_data)
      kickoff = kickoff_at(match_data)
      return nil unless kickoff

      {
        source_match_id: match_data['id'].to_s,
        round_name: match_data['roundName'],
        page_url: match_data['pageUrl'],
        home_name: match_data.dig('home', 'name'),
        away_name: match_data.dig('away', 'name'),
        home_fotmob_id: match_data.dig('home', 'id').presence&.to_i,
        away_fotmob_id: match_data.dig('away', 'id').presence&.to_i,
        kickoff: kickoff,
        score: match_data.dig('status', 'scoreStr')
      }
    end

    def kickoff_at(match_data)
      utc_time = match_data.dig('status', 'utcTime')
      return nil if utc_time.blank?

      DateTime.parse(utc_time).utc
    rescue ArgumentError
      nil
    end

    def all_matches
      page_props&.dig('fixtures', 'allMatches') || []
    end

    def page_props
      @page_props ||= JSON.parse(Nokogiri::HTML(html).css('#__NEXT_DATA__').text)['props']['pageProps']
    rescue JSON::ParserError, NoMethodError => e
      Rails.logger.warn("[calendar] FotMob parse failed for tournament #{tournament.id}: #{e.message}")
      nil
    end

    def html
      fetch("#{LEAGUE_URL}/#{tournament.source_id}/matches")
    rescue RestClient::Exception, SocketError, OpenSSL::SSL::SSLError => e
      Rails.logger.warn("[calendar] FotMob fetch failed for tournament #{tournament.id}: #{e.class}")
      ''
    end

    def fetch(url, hops = MAX_REDIRECTS)
      RestClient::Request.execute(method: :get, url: url, headers: { user_agent: USER_AGENT },
                                  timeout: REQUEST_TIMEOUT)
    rescue RestClient::PermanentRedirect, RestClient::TemporaryRedirect => e
      location = e.response&.headers&.dig(:location)
      raise if location.blank? || hops.zero?

      fetch(absolute(location), hops - 1)
    end

    def absolute(location)
      location.start_with?('http') ? location : URI.join(LEAGUE_URL, location).to_s
    end
  end
end
