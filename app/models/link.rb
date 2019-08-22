class Link < ApplicationRecord
  validates :name, presence: true
  validates :url, presence: true
  validates :url, format: { with: ApplicationRecord::URL_REGEXP, message: 'is invalid' }
end
