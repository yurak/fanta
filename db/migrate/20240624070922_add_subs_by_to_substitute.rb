class AddSubsByToSubstitute < ActiveRecord::Migration[6.1]
  def change
    add_column :substitutes, :subs_by, :integer
  end
end
