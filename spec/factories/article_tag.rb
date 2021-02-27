FactoryBot.define do
  factory :article_tag do
    name { FFaker::Color.name }
    color { FFaker::Color.hex_code }

    tournament
  end
end
