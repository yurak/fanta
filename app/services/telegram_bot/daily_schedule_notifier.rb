# frozen_string_literal: true

module TelegramBot
  class DailyScheduleNotifier < ApplicationService
    def initialize(user)
      @user = user
    end

    def call
      return false if all_deadlines.empty?

      TelegramBot::Sender.call(user, message)
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
        I18n.t('telegram.notifier.daily_schedule.header', locale: locale, time_zone: time_zone),
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
      I18n.t(
        'telegram.notifier.daily_schedule.tour_item',
        locale: locale,
        icon: tour.league.tournament.icon,
        number: tour.number,
        league_name: tour.league.name,
        time: user.local_time(item[:time], '%H:%M')
      )
    end

    def format_auction_round_item(item)
      round = item[:object]
      I18n.t(
        'telegram.notifier.daily_schedule.auction_round_item',
        locale: locale,
        icon: round.auction.league.tournament.icon,
        league_name: round.auction.league.name,
        number: round.number,
        time: user.local_time(item[:time], '%H:%M')
      )
    end

    def format_auction_sales_item(item)
      auction = item[:object]
      I18n.t(
        'telegram.notifier.daily_schedule.auction_sales_item',
        locale: locale,
        icon: auction.league.tournament.icon,
        league_name: auction.league.name,
        time: user.local_time(item[:time], '%H:%M')
      )
    end

    def locale
      user.locale&.to_sym || :en
    end

    def time_zone
      user.time_zone.presence || User::DEFAULT_TIME_ZONE
    end
  end
end
