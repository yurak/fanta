class UrlValidator < ActiveModel::EachValidator
  REGEXP = %r{\Ahttps?://(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*)\z}ix

  def validate_each(record, attribute, value)
    return if value.to_s.match?(REGEXP)

    record.errors.add(attribute, options[:message] || :invalid)
  end
end
