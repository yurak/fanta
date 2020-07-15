class CreateRoundPlayers < ActiveRecord::Migration[5.2]
  def change
    create_table :round_players do |t|
      t.references :tournament_round, foreign_key: true
      t.references :player, foreign_key: true
      t.decimal :score, precision: 4, scale: 2, default: 0
      t.decimal :goals, default: 0
      t.decimal :missed_goals, default: 0
      t.decimal :assists, default: 0
      t.decimal :missed_penalty, default: 0
      t.decimal :scored_penalty, default: 0
      t.decimal :caught_penalty, default: 0
      t.decimal :failed_penalty, default: 0
      t.boolean :yellow_card, default: false
      t.boolean :red_card, default: false
      t.decimal :own_goals, default: 0

      t.timestamps
    end

    add_reference :match_players, :round_player, foreign_key: true

    MatchPlayer.all.each do |mp|
      tournament_round = mp.tour.tournament_round
      round_player = RoundPlayer.find_by(tournament_round: tournament_round, player_id: mp.player_id)
      unless round_player
        RoundPlayer.create(
          tournament_round: tournament_round,
          player_id: mp.player_id,
          score: mp.score,
          goals: mp.goals,
          missed_goals: mp.missed_goals,
          assists: mp.assists,
          missed_penalty: mp.missed_penalty,
          scored_penalty: mp.scored_penalty,
          caught_penalty: mp.caught_penalty,
          failed_penalty: mp.failed_penalty,
          yellow_card: mp.yellow_card,
          red_card: mp.red_card,
          own_goals: mp.own_goals
        )
      end

      mp.update(round_player: round_player)
    end
  end
end
