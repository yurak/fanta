RSpec.describe UrlValidator do
  subject(:record) { model.new }

  let(:model) do
    Class.new do
      include ActiveModel::Validations

      attr_accessor :link

      def self.name
        'Validatable'
      end

      validates :link, url: true
    end
  end

  def valid_with?(value)
    record.link = value
    record.valid?
  end

  it 'accepts an http URL' do
    expect(valid_with?('http://example.com/path')).to be(true)
  end

  it 'accepts an https URL' do
    expect(valid_with?('https://example.com/path')).to be(true)
  end

  it 'rejects a relative path' do
    expect(valid_with?('bad/path/to/file')).to be(false)
  end

  # Why the value is anchored at both ends: unanchored, each of these contains a valid URL and
  # would pass, then be rendered into an href as the whole string.
  it 'rejects a URL with something appended' do
    expect(valid_with?('https://example.com/path and then some')).to be(false)
  end

  it 'rejects a URL with something prepended' do
    expect(valid_with?("javascript:alert(1)\nhttps://example.com")).to be(false)
  end

  it 'rejects a javascript: URL' do
    expect(valid_with?('javascript:alert(1)')).to be(false)
  end

  it 'rejects an empty value, unless the caller allows blank' do
    expect(valid_with?('')).to be(false)
  end

  it 'adds the :invalid error' do
    valid_with?('nonsense')

    expect(record.errors.details[:link]).to eq([{ error: :invalid }])
  end
end
