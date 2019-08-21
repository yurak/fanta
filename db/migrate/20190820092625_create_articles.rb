class CreateArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :articles do |t|
      t.string :title
      t.string :summary
      t.string :description
      t.string :image_url

      t.timestamps
    end
  end
end
