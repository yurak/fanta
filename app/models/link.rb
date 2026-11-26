class Link < ApplicationRecord
  belongs_to :tournament

  validates :name, presence: true
  validates :url, presence: true, url: true
end
