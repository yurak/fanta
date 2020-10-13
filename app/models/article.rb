class Article < ApplicationRecord
  belongs_to :article_tag, optional: true

  enum status: %i[published hidden]

  validates :title, presence: true
  validates :description, presence: true
  validates :image_url, format: { with: ApplicationRecord::URL_REGEXP,
                                  message: 'is invalid',
                                  allow_blank: true }

  def image
    image_url.presence || 'article1.png'
  end

  def internal_image
    internal_image_url.presence || image
  end

  def related_articles
    articles = Article.where(article_tag: article_tag).order(id: :desc).reject { |art| art == self } if article_tag

    articles = Article.all.order(id: :desc).reject { |art| art == self } unless articles

    articles.take(2)
  end
end
