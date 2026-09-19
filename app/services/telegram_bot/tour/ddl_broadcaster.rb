# frozen_string_literal: true

module TelegramBot
  module Tour
    class DdlBroadcaster < ApplicationService
      REMINDER_HOURS = [5, 3, 2, 1].freeze
      WINDOW = 10.minutes

      def call
        REMINDER_HOURS.each do |hours|
          tours_due_in(hours).each do |tour|
            Notifications::Creator.call(notifiable: tour, kind: :"tour_ddl_#{hours}h")
          end
        end
      end

      private

      def tours_due_in(hours)
        target = Time.current + hours.hours

        ::Tour.set_lineup
              .joins(:tournament_round, :league)
              .where(leagues: { status: ::League.statuses[:active] })
              .where(tournament_rounds: { deadline: (target - WINDOW)..target })
      end
    end
  end
end
