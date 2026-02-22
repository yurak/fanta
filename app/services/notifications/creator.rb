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
    rescue KeyError => e
      raise ArgumentError, "Invalid kind/priority enum value: #{e.message}"
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

    def teams_for
      case kind
      when :tour_opened, :tour_moderated, :tour_closed
        notifiable&.league&.teams.to_a.select { |t| t.user_id.present? }
      else
        raise ArgumentError, "Notifications::Creator does not know how to build teams for kind=#{kind}"
      end
    end

    def already_notified_team_ids
      Notification.where(
        notifiable_type: notifiable.class.name,
        notifiable_id: notifiable.id,
        kind: kind_value
      ).pluck(:team_id).to_set
    end
  end
end
# rubocop:enable Rails/SkipsModelValidations
