class AddSubstitutestoLineup < ActiveRecord::Migration[6.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:lineups, :substitutes)
      add_column :lineups, :substitutes, :text
    end
  end
end
