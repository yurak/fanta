FactoryBot.define do
  factory :team do
    sequence(:name) { |i| "name#{i}" }

    association :league
  end
end
