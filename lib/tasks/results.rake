namespace :results do
  desc 'Update results total score of active leagues'
  task update_total_scores: :environment do
    League.active.each do |league|
      league.teams.each do |team|
        season_total_score = team.lineups.by_league(league.id).sum(&:total_score)

        team.results.last.update(
          total_score: season_total_score
        )
      end
    end
  end
end
