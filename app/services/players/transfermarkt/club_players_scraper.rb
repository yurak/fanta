# frozen_string_literal: true

# rubocop:disable Rails/Output
module Players
  module Transfermarkt
    class ClubPlayersScraper < ApplicationService
      MAX_ATTEMPTS = 3

      def initialize(clubs:, writer:)
        @clubs = clubs
        @writer = writer
      end

      def call
        @clubs.each_with_index do |club, idx|
          # next if (idx + 1) < 1
          # next if (idx + 1) > 15
          puts "--------#{idx + 1}---#{club.name}--------"
          next unless club.tm_url

          process_club(club)
          puts '/////////////////////////////////////'
        end
      end

      private

      def process_club(club)
        html_page = fetch_club_page(club)
        return unless html_page

        players = html_page.css('.inline-table .hauptlink')
        actual_ids = process_players(club, players)
        process_missed_players(club, actual_ids)
      end

      def fetch_club_page(club)
        html = with_retry(label: "club #{club.name}") do
          Players::Transfermarkt::BrowserClient.new.fetch_html(
            club.tm_url,
            headless: true,
            cache_key: "club_#{club.id}",
            ttl: 7 * 86_400
          )
        end
        Nokogiri::HTML(html) if html
      end

      def process_players(club, players)
        counts = { old: 0, new: 0 }
        actual_ids = []

        players.each do |player_data|
          tm_id = player_data.children[1].attributes['href'].value.split('/').last
          actual_ids << tm_id.to_i
          handle_player(Player.find_by(tm_id: tm_id), tm_id, club, counts)
        end

        puts '------------------'
        actual_ids
      end

      def handle_player(player, tm_id, club, counts)
        if player
          counts[:old] += 1
          change = player.club.name == club.name ? '' : " >>>> #{club.name} !!!!!!"
          puts "#{counts[:old]} - #{player.name} - #{player.id} / #{player.tm_id} --- #{player.club.name}#{change}"
        else
          counts[:new] += 1
          puts "NEW #{counts[:new]} .... #{tm_id}"
          fetch_and_write_new_player(tm_id, club)
        end
      end

      def fetch_and_write_new_player(tm_id, club)
        result = with_retry(label: "TM id #{tm_id}") do
          Players::Transfermarkt::Parser.call(tm_id)
        end
        return unless result

        @writer << ['', result[:first_name], result[:name], result[:nationality], club.name,
                    result[:position1], result[:position2], result[:position3], result[:tm_url], '',
                    result[:tm_pos1], result[:tm_pos2], result[:tm_pos3], '', '',
                    result[:tm_price], result[:number], result[:birth_date], result[:height]]
      end

      def process_missed_players(club, actual_ids)
        missed_ids = club.players.where.not(tm_id: nil).pluck(:tm_id).uniq - actual_ids
        return unless missed_ids.any?

        puts "Missed list: #{missed_ids.join(' ')}"
        missed_ids.each { |pl_tm_id| check_missed_player(club, pl_tm_id) }
      end

      def check_missed_player(club, pl_tm_id)
        player = club.players.find_by(tm_id: pl_tm_id)
        result = with_retry(label: player.tm_id.to_s) do
          Players::Transfermarkt::Parser.call(pl_tm_id, position_skip: true)
        end
        return unless result

        new_club = result[:club_name] || "XXX #{result[:tm_club_name]}"
        change = player.club.name == result[:club_name] ? 'RESERVE' : "#{player.club.name} >>>> #{new_club}"
        puts "MISSED .... #{player.name} - #{player.id} / #{player.tm_id} --- #{change}"
      end

      def retryable_errors
        [RestClient::Exception, Playwright::TimeoutError]
      end

      def with_retry(label:)
        attempts = 0
        begin
          attempts += 1
          yield
        rescue *retryable_errors => e
          if attempts <= MAX_ATTEMPTS
            puts "Retry ##{attempts} for #{label}"
            retry
          else
            puts "#{label} skipped: #{e}"
            nil
          end
        end
      end
    end
  end
end
# rubocop:enable Rails/Output
