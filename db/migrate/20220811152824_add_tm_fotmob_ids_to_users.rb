class AddTmFotmobIdsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :players, :tm_id, :integer
    add_column :players, :fotmob_id, :integer

    add_index :players, :tm_id, unique: true
    add_index :players, :fotmob_id, unique: true
    remove_index :players, name: "index_players_on_name_and_first_name_and_tm_url"

    Player.all.each do |player|
      next unless player.tm_url

      player.update(tm_id: player.tm_url.split('/').last)
    end
  end
end
