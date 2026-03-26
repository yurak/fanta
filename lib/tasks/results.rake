namespace :results do
  desc 'Update results total score of active leagues'
  task update_total_scores: :environment do
    League.active.each do |league|
      Results::TotalScoreUpdater.call(league)
    end
  end
end
