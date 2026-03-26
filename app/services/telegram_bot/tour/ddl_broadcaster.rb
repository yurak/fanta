# frozen_string_literal: true

module TelegramBot
  module Tour
    class DdlBroadcaster < ApplicationService
      def call
        ::League.active.each do |league|
          league.tours.set_lineup.each do |tour|
            next unless tour.tournament_round.deadline
            next if Time.current < (tour.tournament_round.deadline - 3.hours)

            TelegramBot::Tour::DdlNotifier.call(tour)
          end
        end
      end
    end
  end
end
