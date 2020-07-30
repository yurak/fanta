FactoryBot.define do
  factory :tour do
    association :league
    association :tournament_round

    trait :serie_a do
      association :league, :serie_a
    end
  end
end
