class JoinsController < ApplicationController
  def index
    @has_active_leagues = current_user.teams.joins(:league).exists?(leagues: { status: :active })
    @user_joins = current_user.joins.where.not(status: :rejected).includes(:tournament, team: :auction_bids).order(created_at: :desc)
    @tournaments = Tournament.mantra.open_join.where.not(id: joined_tournament_ids).with_join_stats
  end

  def show
    @join = current_user.joins.find_by(id: params[:id])
    redirect_to joins_path unless @join
  end

  private

  def joined_tournament_ids
    join_ids = current_user.joins.where.not(status: :rejected).pluck(:tournament_id)
    active_team_ids = current_user.teams.joins(:league).where(leagues: { status: :active }).pluck('leagues.tournament_id')
    (join_ids + active_team_ids).uniq
  end
end
