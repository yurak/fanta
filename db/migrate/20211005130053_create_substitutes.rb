class CreateSubstitutes < ActiveRecord::Migration[5.2]
  def change
    create_table :substitutes do |t|
      t.bigint :main_mp_id, null: false
      t.bigint :reserve_mp_id, null: false
      t.bigint :in_rp_id, null: false
      t.bigint :out_rp_id, null: false

      t.timestamps
    end
  end
end
