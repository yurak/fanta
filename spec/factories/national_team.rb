FactoryBot.define do
  factory :national_team do
    sequence(:code) { |i| "nt#{i}" }

    association :tournament
  end
end
