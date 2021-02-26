class ArticleTag < ApplicationRecord
  belongs_to :tournament, optional: true

  has_many :articles, dependent: :destroy

  enum status: { published: 0, hidden: 1 }

  validates :name, presence: true
  validates :color, presence: true, length: { is: 6 }
end
