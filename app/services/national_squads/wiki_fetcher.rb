module NationalSquads
  # Fetches the articles for a list of national teams and hands back the latest revision of each.
  #
  # Reusable for whatever tournament comes next: the only thing tied to a competition is the CSV the
  # caller reads, and a team Wikipedia files under another name goes in ARTICLES below.
  class WikiFetcher < ApplicationService
    API = 'https://en.wikipedia.org/w/api.php'.freeze
    USER_AGENT = 'fanta-squad-check/1.0'.freeze
    BATCH = 8 # the API's ceiling for full-content requests
    TIMEOUT = 60

    # Our team name -> the article title, where the two differ.
    ARTICLES = {
      'Czechia' => 'Czech Republic national football team',
      'Turkiye' => 'Turkey national football team',
      'Ireland' => 'Republic of Ireland national football team',
      'Sweden' => "Sweden men's national football team"
    }.freeze

    attr_reader :teams

    def initialize(teams)
      @teams = teams
    end

    def self.article_for(team)
      ARTICLES.fetch(team, "#{team} national football team")
    end

    # { team => { wikitext:, edited_at: } }, missing entirely for a team we could not read
    def call
      pages = fetch_pages

      teams.each_with_object({}) do |team, acc|
        revision = pages.dig(self.class.article_for(team), 'revisions', 0)
        next if revision.nil?

        acc[team] = { wikitext: revision.dig('slots', 'main', 'content'), edited_at: revision['timestamp'] }
      end
    end

    private

    def fetch_pages
      titles = teams.map { |team| self.class.article_for(team) }

      titles.each_slice(BATCH).with_object({}) do |slice, pages|
        data = request(slice)
        data['pages'].to_a.each { |page| pages[page['title']] = page }
        (data['redirects'].to_a + data['normalized'].to_a).each do |mapping|
          pages[mapping['from']] = pages[mapping['to']] if pages.key?(mapping['to'])
        end
      end
    end

    def request(titles)
      response = RestClient::Request.execute(
        method: :get, url: API, timeout: TIMEOUT,
        headers: { user_agent: USER_AGENT, params: params_for(titles) }
      )

      JSON.parse(response.body)['query'] || {}
    end

    def params_for(titles)
      { action: 'query', format: 'json', formatversion: '2', redirects: '1',
        prop: 'revisions', rvprop: 'content|timestamp', rvslots: 'main', titles: titles.join('|') }
    end
  end
end
