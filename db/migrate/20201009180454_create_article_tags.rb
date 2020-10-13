class CreateArticleTags < ActiveRecord::Migration[5.2]
  def change
    create_table :article_tags do |t|
      t.string :name, null: false, default: ''
      t.string :color, null: false, default: ''
      t.integer :tournament_id
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_column :articles, :article_tag_id, :integer
    add_column :articles, :internal_image_url, :string
  end
end
