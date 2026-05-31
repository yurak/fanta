class JoinsController < ApplicationController
  def index
    @has_active_leagues = current_user.teams.joins(:league).exists?(leagues: { status: :active })
    @user_joins = current_user.joins.where.not(status: :rejected).includes(:tournament, :auction_bid).order(created_at: :desc)
    @tournaments = Tournament.open_join.where.not(id: joined_tournament_ids).with_join_stats
    mantra_tournament_ids = @tournaments.select(&:mantra?).map(&:id)
    @existing_teams = current_user.teams.where(tournament_id: mantra_tournament_ids).index_by(&:tournament_id)
  end

  def show
    @join = current_user.joins.find_by(id: params[:id])
    redirect_to joins_path unless @join
  end

  private

  def joined_tournament_ids
    join_ids = current_user.joins.where.not(status: :rejected).pluck(:tournament_id)

    mantra_team_ids = current_user.teams
                                  .joins(league: :tournament)
                                  .where(leagues: { status: :active }, tournaments: { mode: :mantra })
                                  .pluck('leagues.tournament_id')

    fanta_team_ids = current_user.teams
                                 .joins(league: :tournament)
                                 .where(leagues: { status: :active, open_for_join: true }, tournaments: { mode: :fanta })
                                 .pluck('leagues.tournament_id')

    (join_ids + mantra_team_ids + fanta_team_ids).uniq
  end
end
