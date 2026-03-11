# rubocop:disable Rails/SkipsModelValidations
module Notifications
  class Creator < ApplicationService
    attr_reader :notifiable, :kind, :priority, :kind_value, :status_value, :priority_value

    def initialize(notifiable:, kind:, priority: :normal)
      @notifiable = notifiable
      @kind = kind.to_sym
      @priority = priority.to_sym
      @kind_value = Notification.kinds.fetch(@kind.to_s)
      @priority_value = Notification.priorities.fetch(@priority.to_s)
      @status_value = Notification.statuses.fetch(Notification::PENDING)
    rescue KeyError => e
      raise ArgumentError, "Invalid kind/priority enum value: #{e.message}"
    end

    def call
      teams = eligible_teams
      return false if teams.empty?

      Notification.insert_all!(prepare_rows(teams, Time.current))
      true
    end

    private

    def prepare_rows(teams, time)
      teams.filter_map do |team|
        next unless team.id

        {
          team_id: team.id,
          notifiable_type: notifiable.class.name,
          notifiable_id: notifiable.id,
          kind: kind_value,
          status: status_value,
          priority: priority_value,
          created_at: time,
          updated_at: time
        }
      end
    end

    def eligible_teams
      teams_for.reject { |t| already_notified_team_ids.include?(t.id) }
    end

    LEAGUE_TEAM_KINDS = %i[
      tour_opened tour_moderated tour_closed
      auction_sales_open auction_closed auction_sales_ddl
    ].freeze

    def teams_for
      if LEAGUE_TEAM_KINDS.include?(kind)
        league_teams
      elsif kind == :auction_start_bids
        auction_bid_teams
      elsif kind == :auction_round_ddl
        auction_round_ddl_teams
      elsif kind == :auction_squad_complete
        auction_squad_complete_teams
      else
        raise ArgumentError, "Notifications::Creator does not know how to build teams for kind=#{kind}"
      end
    end

    def league_teams
      with_user(notifiable&.league&.teams.to_a || [])
    end

    def auction_bid_teams
      with_user(notifiable&.auction_bids&.map(&:team) || [])
    end

    def auction_round_ddl_teams
      with_user(notifiable&.auction_bids&.initial_ongoing&.map(&:team) || [])
    end

    def auction_squad_complete_teams
      with_user(notifiable&.auction_bids&.map(&:team)&.select(&:full_squad?) || [])
    end

    def with_user(teams)
      teams.select { |t| t.user_id.present? }
    end

    def already_notified_team_ids
      Notification.where(notifiable_scope.merge(kind: kind_value)).pluck(:team_id).to_set
    end

    def notifiable_scope
      if kind == :auction_squad_complete
        { notifiable_type: 'AuctionRound', notifiable_id: notifiable.auction.auction_rounds.pluck(:id) }
      else
        { notifiable_type: notifiable.class.name, notifiable_id: notifiable.id }
      end
    end
  end
end
# rubocop:enable Rails/SkipsModelValidations
