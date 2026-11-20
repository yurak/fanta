class Configuration < ApplicationRecord
  validates :provider, presence: true, uniqueness: true

  def self.sofa_server_url
    find_by(provider: 'sofascore')&.payload
  end
end
