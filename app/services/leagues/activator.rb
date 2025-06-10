module Leagues
  class Activator < ApplicationService
    def initialize(league_id)
      @league_id = league_id
    end

    def call
      return false unless league&.initial?
      return false if league.teams.empty?

      League.transaction do
        config_teams
        create_auctions
        create_results
        create_tours

        league.active!
      end
    end

    private

    def league
      @league ||= League.find_by(id: @league_id)
    end

    def config_teams
      league.teams.each do |team|
        team.players.clear
        team.update(budget: Team::DEFAULT_BUDGET, transfer_slots: Team::SLOTS_BY_AUCTION * auctions_number)
      end
    end

    def create_auctions
      auctions_number.times { |i| league.auctions.create(number: i + 1, base_date: norm_date(auctions_dates[i]), sales_count: 0) }
    end

    def create_results
      Results::Creator.call(league.id)
    end

    def create_tours
      CalendarCreator.call(league.id, tours_number)
    end

    def auctions_number
      @auctions_number ||= league.auction_number
    end

    def norm_date(month_name)
      month_number = Date::MONTHNAMES.index(month_name.capitalize)
      return unless month_number

      candidate_date = Date.new(Time.zone.today.year, month_number, 1)
      year = candidate_date > Time.zone.today ? candidate_date.year : candidate_date.next_year.year
      "#{month_name.capitalize}, #{year}"
    end

    def auctions_dates
      @auctions_dates ||= base_auctions_dates.last(auctions_number)
    end

    def base_auctions_dates
      YAML.load_file(Rails.root.join('config/mantra/auctions_calendar.yml'))[league.tournament.code]
    end

    def tours_number
      league.tournament.tournament_rounds.by_season(league.season_id).count - league.tour_difference
    end
  end
end
