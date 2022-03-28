class AddHumanNameToPositions < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :ital_pos_naming, :boolean, null: false, default: false
    add_column :positions, :human_name, :string, null: false, default: ''

    remove_column :users, :summer_balance, :decimal
    remove_column :players, :status, :integer
    remove_column :tournament_rounds, :start_time, :datetime

    # Fix foreign key after migration to Rails 6.1
    add_foreign_key :clubs, :tournaments
    add_foreign_key :leagues, :seasons
    add_foreign_key :links, :tournaments
    add_foreign_key :match_players, :round_players
    add_foreign_key :players, :national_teams
    add_foreign_key :results, :leagues
    add_foreign_key :teams, :leagues
    add_foreign_key :teams, :users
    add_foreign_key :tours, :leagues
    add_foreign_key :tours, :tournament_rounds
    add_foreign_key :transfers, :auctions
  end
end
