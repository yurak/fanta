class AddHistoryToResults < ActiveRecord::Migration[6.1]
  def change
    add_column :results, :history, :text, default: '[]'
  end
end
