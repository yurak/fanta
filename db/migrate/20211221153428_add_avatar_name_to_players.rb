class AddAvatarNameToPlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :avatar_name, :string
  end
end
