class Article < ApplicationRecord
  # TODO: Add nested parameter - articles shown only in league news

  enum status: %i[published hidden]

  validates :title, presence: true
  validates :description, presence: true
  validates :image_url, format: { with: ApplicationRecord::URL_REGEXP,
                                  message: 'is invalid',
                                  allow_blank: true}

  def image
    image_url.present? ? image_url : 'article1.png'
  end
end
