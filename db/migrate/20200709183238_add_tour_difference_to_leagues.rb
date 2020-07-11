class AddTourDifferenceToLeagues < ActiveRecord::Migration[5.2]
  def change
    add_column :leagues, :tour_difference, :integer, null: false, default: 0
  end
end
