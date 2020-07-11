class AddPseudonymToPlayer < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :pseudonym, :string, null: false, default: ''
  end
end
