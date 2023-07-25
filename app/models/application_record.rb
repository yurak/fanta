class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  CONTENT_TYPE_PNG = 'image/png'.freeze
  URL_REGEXP = %r{https?://(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*)}ix.freeze
end
