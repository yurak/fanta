FactoryBot.define do
  factory :league do
    sequence(:name) { |i| "name#{i}" }
    association :tournament
    association :season

    trait :serie_a do
      association :tournament, :serie_a
    end
  end
end
