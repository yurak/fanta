class AddLineupsGeneratedToTours < ActiveRecord::Migration[6.1]
  def change
    add_column :tours, :lineups_generated, :boolean, default: false, null: false

    reversible do |dir|
      dir.up { execute 'UPDATE tours SET lineups_generated = TRUE WHERE status = 2' }
    end
  end
end
