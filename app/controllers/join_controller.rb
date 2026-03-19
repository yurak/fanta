class JoinController < ApplicationController
  def index
    ids = joined_tournament_ids
    @user_joins = current_user.joins.where.not(status: :rejected).includes(:tournament, team: :auction_bids).order(created_at: :desc)
    @tournaments = Tournament.mantra
                             .where(open_join: true)
                             .where.not(id: ids)
                             .select(
                               'tournaments.*',
                               "COUNT(DISTINCT CASE WHEN leagues.status = #{League.statuses[:active]} " \
                               'THEN teams.id END) AS active_teams_count',
                               'COUNT(DISTINCT joins.id) AS joins_count'
                             )
                             .joins('LEFT JOIN leagues ON leagues.tournament_id = tournaments.id')
                             .joins('LEFT JOIN teams ON teams.league_id = leagues.id')
                             .joins('LEFT JOIN joins ON joins.tournament_id = tournaments.id')
                             .group('tournaments.id')
  end

  private

  def joined_tournament_ids
    join_ids = current_user.joins.where.not(status: :rejected).pluck(:tournament_id)
    active_team_ids = current_user.teams.joins(:league).where(leagues: { status: :active }).pluck('leagues.tournament_id')
    (join_ids + active_team_ids).uniq
  end
end
