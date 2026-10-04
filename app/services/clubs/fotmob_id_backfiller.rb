module Clubs
  class FotmobIdBackfiller < ApplicationService
    attr_reader :tournament

    def initialize(tournament)
      @tournament = tournament
    end

    def call
      pairs = fotmob_sides
      return 0 if pairs.empty?

      resolved = resolve(pairs)
      resolved.count { |club, fotmob_id| assign(club, fotmob_id) }
    end

    private

    def fotmob_sides
      TournamentRounds::FotmobCalendarParser.call(tournament).each_with_object({}) do |entry, acc|
        next if entry[:home_fotmob_id].blank? || entry[:away_fotmob_id].blank?

        acc[entry[:source_match_id].to_s] = [entry[:home_fotmob_id], entry[:away_fotmob_id]]
      end
    end

    def resolve(pairs)
      matches.each_with_object({}) do |match, acc|
        home_id, away_id = pairs[fotmob_match_id(match)]
        next if home_id.blank?

        acc[match.host_club] ||= home_id
        acc[match.guest_club] ||= away_id
      end.compact
    end

    def fotmob_match_id(match)
      match.page_url.to_s[/#(\d+)\z/, 1] || match.source_match_id.to_s
    end

    def matches
      TournamentMatch.joins(:tournament_round)
                     .where(tournament_rounds: { tournament_id: tournament.id })
                     .where.not(page_url: '')
                     .includes(:host_club, :guest_club)
    end

    def assign(club, fotmob_id)
      return false if club.blank? || fotmob_id.blank? || club.fotmob_id == fotmob_id
      return false if Club.where.not(id: club.id).exists?(fotmob_id: fotmob_id)

      club.update(fotmob_id: fotmob_id)
    end
  end
end
