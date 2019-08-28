class AddDeadlineToTours < ActiveRecord::Migration[5.2]
  def change
    add_column :tours, :deadline, :datetime
  end
end
