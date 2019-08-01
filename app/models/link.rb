class Link < ApplicationRecord
  URL_REGEXP = /\A(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\Z/ix

  validates :name, presence: true
  validates :url, presence: true
  validates :url, format: { with: URL_REGEXP, message: 'is invalid' }
end
