FactoryBot.define do
  factory :league do
    sequence(:name) { |i| "name#{i}" }
    association :tournament

    trait :serie_a do
      association :tournament, :serie_a
    end
  end
end
