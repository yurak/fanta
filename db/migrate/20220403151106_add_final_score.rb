class AddFinalScore < ActiveRecord::Migration[6.1]
  def change
    add_column :round_players, :final_score, :decimal,precision: 4, scale: 2, default: 0
    add_column :lineups, :final_score, :decimal,precision: 4, scale: 2, default: 0

    RoundPlayer.where(score: 0).where.missing(:match_players).destroy_all
    Tour.closed.each do |tour|
      RoundPlayers::Updater.call(tour.tournament_round)

      Lineups::Updater.call(tour)
    end
  end
end
