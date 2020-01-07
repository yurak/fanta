class Article < ApplicationRecord
  enum status: %i[published hidden]

  validates :title, presence: true
  validates :description, presence: true
  validates :image_url, format: { with: ApplicationRecord::URL_REGEXP,
                                  message: 'is invalid',
                                  allow_blank: true }

  def image
    image_url.presence || 'article1.png'
  end
end
