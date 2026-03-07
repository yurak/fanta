class AddSkipRoundCheckToTournaments < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments, :skip_round_check, :boolean, default: false, null: false
  end
end
