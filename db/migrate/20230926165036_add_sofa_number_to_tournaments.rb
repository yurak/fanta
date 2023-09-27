class AddSofaNumberToTournaments < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments, :sofa_number, :string, null: false, default: ''
  end
end
