class AddUniqIndex < ActiveRecord::Migration[6.1]
  def change
    add_index :configurations, :provider, unique: true
  end
end