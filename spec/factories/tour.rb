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

    factory :postponed_tour do
      status { :postponed }
    end

    factory :serie_a_tour do
      association :league, :serie_a_league
    end

    factory :epl_tour do
      association :league, :epl_league
    end

    factory :bundes_tour do
      association :league, :bundes_league
    end

    factory :laliga_tour do
      association :league, :laliga_league
    end

    factory :ligue1_tour do
      association :league, :ligue1_league
    end

    factory :euro_tour do
      association :league, :euro_league
    end
  end
end
