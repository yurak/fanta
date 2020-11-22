class ArticleTag < ApplicationRecord
  belongs_to :tournament, optional: true

  has_many :articles

  enum status: %i[published hidden]

  validates :name, presence: true
  validates :color, presence: true, length: { is: 6 }
end
