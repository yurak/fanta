class Configuration < ApplicationRecord
  validates :provider, presence: true, uniqueness: true


  def self.rollbar_token
    find_by(provider: 'rollbar')&.payload
  end
end
