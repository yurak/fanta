FactoryBot.define do
  factory :tournament do
    sequence(:name) { |i| "name#{i}" }
    code { "serie_a" }
  end
end
