class Configuration < ApplicationRecord
  validates :provider, presence: true, uniqueness: true

  def self.rollbar_token
    find_by(provider: 'rollbar')&.payload
  end

  def self.sofa_server_url
    find_by(provider: 'sofascore')&.payload
  end
end
