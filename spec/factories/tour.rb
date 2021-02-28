FactoryBot.define do
  factory :tour do
    sequence(:number) { |i| i }

    association :league
    association :tournament_round

    factory :set_lineup_tour do
      status { :set_lineup }
    end

    factory :locked_tour do
      status { :locked }
    end

    factory :closed_tour do
      status { :closed }
    end

    trait :serie_a do
      association :league, :serie_a
    end
  end
end
