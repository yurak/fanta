class AddStatusToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :status, :integer, null: false, default: 0

    Article.all.reload.each do |article|
      article.published!
    end
  end
end
