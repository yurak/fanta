class CreateEclTournament < ActiveRecord::Migration[5.2]
  def change
    add_column :tournaments, :eurocup, :boolean, default: false

    add_reference :clubs, :ec_tournament, foreign_key: true

    add_column :tournament_matches, :time, :string, null: false, default: ''
    add_column :tournament_matches, :date, :string, null: false, default: ''
    add_column :tournament_matches, :round_name, :string, null: false, default: ''

    tournament = Tournament.find_or_create_by(
      name: 'Champions League',
      code: 'champions_league'
    )

    TournamentRounds::Creator.call(tournament.id, Season.last.id, count: 12) if tournament
  end
end
