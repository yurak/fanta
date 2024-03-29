class Article < ApplicationRecord
  belongs_to :article_tag, optional: true

  enum status: { initial: 0, published: 1, archived: 2 }

  validates :title, presence: true
  validates :description, presence: true
  validates :image_url, format: { with: ApplicationRecord::URL_REGEXP,
                                  allow_blank: true }

  default_scope { includes(:article_tag) }

  def image
    image_url.presence || 'article1.png'
  end

  def internal_image
    internal_image_url.presence || image
  end

  def related_articles
    articles = Article.published.where(article_tag: article_tag).order(id: :desc).reject { |art| art == self } if article_tag

    articles = Article.published.order(id: :desc).reject { |art| art == self } if articles.empty?

    articles.take(2)
  end
end
