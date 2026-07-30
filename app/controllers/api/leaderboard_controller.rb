module Api
  class LeaderboardController < Api::ApplicationController
    skip_before_action :authenticate_user!, only: :index

    def index
      paged = paginate(leaderboard.call)
      users = User.where(id: paged.map(&:user_id)).includes(teams: [{ league: :tournament }, :results]).index_by(&:id)

      render json: {
        data: paged.map { |entry| serialize(entry, users[entry.user_id]) },
        meta: response_options(paged).merge(current_user: current_user_entry)
      }
    end

    private

    def leaderboard
      @leaderboard ||= Managers::Leaderboard.new(
        metric: params[:metric],
        include_newbies: params[:include_newbies],
        min_matches: params[:min_matches],
        tournament_id: params[:tournament_id]
      )
    end

    def serialize(entry, user)
      LeaderboardEntrySerializer.new(user, rank: entry.rank, value: entry.value, matches: entry.matches)
    end

    def current_user_entry
      return unless current_user

      entry = leaderboard.entry_for(current_user.id)
      return unless entry

      user = User.includes(teams: [{ league: :tournament }, :results]).find(current_user.id)
      serialize(entry, user)
    end
  end
end
