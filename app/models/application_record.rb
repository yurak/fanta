class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  CONTENT_TYPE_PNG = 'image/png'.freeze
  URL_REGEXP = %r{\A(http|https)://[a-z0-9]+([\-.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?\Z}ix.freeze
end
