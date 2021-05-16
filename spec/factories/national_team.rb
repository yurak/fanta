FactoryBot.define do
  factory :national_team do
    sequence(:code) { |i| "nt#{i}" }
    sequence(:name) { FFaker::Address.country }

    association :tournament
  end
end
