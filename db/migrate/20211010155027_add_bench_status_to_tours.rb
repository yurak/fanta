class AddBenchStatusToTours < ActiveRecord::Migration[5.2]
  def change
    add_column :tours, :bench_status, :integer, null: false, default: 0
  end
end
