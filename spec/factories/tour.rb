FactoryBot.define do
  factory :tour do
    association :league

    trait :serie_a do
      association :league, :serie_a
    end
  end
end
