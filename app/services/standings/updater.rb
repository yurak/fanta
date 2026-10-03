module Standings
  class Updater < ApplicationService
    attr_reader :tournament, :season

    def initialize(tournament, season: nil)
      @tournament = tournament
      @season = season || Season.last
    end

    def call
      return 0 unless club_tournament?

      rows = FotmobParser.call(tournament)
      return 0 if rows.empty?

      ActiveRecord::Base.transaction do
        rows.each { |row| write_row(row) }
        drop_surplus(rows.size)
      end

      rows.size
    end

    private

    # National tournaments have no clubs to link, and before a draw FotMob fills their table with
    # placeholders ("1A", "2A") that carry real-looking ids — a table of those is worse than none.
    def club_tournament?
      tournament.clubs.exists? || tournament.ec_clubs.exists?
    end

    def write_row(row)
      standing = Standing.find_or_initialize_by(tournament: tournament, season: season, position: row[:position])
      standing.assign_attributes(row.except(:position).merge(club: club_for(row)))
      standing.save
    end

    def drop_surplus(size)
      Standing.where(tournament: tournament, season: season).where(position: (size + 1)..).delete_all
    end

    def club_for(row)
      clubs_by_fotmob_id[row[:fotmob_team_id]]
    end

    def clubs_by_fotmob_id
      @clubs_by_fotmob_id ||= Club.where.not(fotmob_id: nil).index_by(&:fotmob_id)
    end
  end
end
