class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  CONTENT_TYPE_PNG = 'image/png'.freeze
end
