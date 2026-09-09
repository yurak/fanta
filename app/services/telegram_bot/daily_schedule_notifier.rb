# frozen_string_literal: true

module TelegramBot
  class DailyScheduleNotifier < ApplicationService
    include TelegramBot::HtmlMessage
    include TelegramBot::Recipient

    LINEUP_SET = '✅'
    LINEUP_MISSING = '❌'

    def initialize(user)
      @user = user
    end

    def call
      return false if all_deadlines.empty?

      send_html(user, message)
      true
    end

    private

    attr_reader :user

    def all_deadlines
      @all_deadlines ||= (tour_items + auction_round_items + auction_sales_items).sort_by { |item| item[:time] }
    end

    def tour_items
      tour_deadlines.map do |tour|
        { time: tour.tournament_round.deadline, type: :tour, object: tour }
      end
    end

    def auction_round_items
      auction_round_deadlines.map do |round|
        { time: round.deadline, type: :auction_round, object: round }
      end
    end

    def auction_sales_items
      auction_sales_deadlines.map do |auction|
        { time: auction.deadline, type: :auction_sales, object: auction }
      end
    end

    def tour_deadlines
      ::Tour.set_lineup
            .joins(:tournament_round, league: :teams)
            .where(teams: { id: user_team_ids })
            .where(tournament_rounds: { deadline: today_range })
            .includes(league: :tournament)
    end

    def auction_round_deadlines
      ::AuctionRound.active
                    .joins(:auction_bids)
                    .where(auction_bids: { team_id: user_team_ids })
                    .where(deadline: today_range)
                    .includes(auction: { league: :tournament })
    end

    def auction_sales_deadlines
      ::Auction.sales
               .joins(league: :teams)
               .where(teams: { id: user_team_ids })
               .where(deadline: today_range)
               .includes(league: :tournament)
    end

    def user_team_ids
      @user_team_ids ||= user.teams.where.not(league_id: nil).pluck(:id)
    end

    def today_range
      Time.current..24.hours.from_now
    end

    def message
      lines = all_deadlines.map { |item| format_item(item) }
      [
        html_message('telegram.notifier.daily_schedule.header', locale: locale, time_zone: time_zone),
        '',
        *lines,
        '',
        '#schedule'
      ].join("\n")
    end

    def format_item(item)
      case item[:type]
      when :tour then format_tour_item(item)
      when :auction_round then format_auction_round_item(item)
      when :auction_sales then format_auction_sales_item(item)
      end
    end

    def format_tour_item(item)
      tour = item[:object]
      html_message(
        'telegram.notifier.daily_schedule.tour_item',
        locale: locale,
        icon: tour.league.tournament.icon,
        number: tour.number,
        league_name: tour.league.name,
        time: user.local_time(item[:time], '%H:%M'),
        url: Rails.application.routes.url_helpers.tour_url(tour),
        lineup_status: lineup_status(tour)
      )
    end

    def lineup_status(tour)
      tours_with_lineup.include?(tour.id) ? LINEUP_SET : LINEUP_MISSING
    end

    def tours_with_lineup
      @tours_with_lineup ||= ::Lineup.where(tour_id: tour_deadlines.map(&:id), team_id: user_team_ids)
                                     .pluck(:tour_id)
                                     .to_set
    end

    def format_auction_round_item(item)
      round = item[:object]
      html_message(
        'telegram.notifier.daily_schedule.auction_round_item',
        locale: locale,
        icon: round.auction.league.tournament.icon,
        league_name: round.auction.league.name,
        number: round.number,
        time: user.local_time(item[:time], '%H:%M'),
        url: Rails.application.routes.url_helpers.auction_round_url(round)
      )
    end

    def format_auction_sales_item(item)
      auction = item[:object]
      html_message(
        'telegram.notifier.daily_schedule.auction_sales_item',
        locale: locale,
        icon: auction.league.tournament.icon,
        league_name: auction.league.name,
        time: user.local_time(item[:time], '%H:%M'),
        url: Rails.application.routes.url_helpers.sales_league_auction_url(auction.league, auction)
      )
    end
  end
end
