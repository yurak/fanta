FactoryBot.define do
  factory :tour do
    sequence(:number) { |i| i }

    league
    tournament_round

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

    factory :italy_tour do
      league factory: %i[league italy_league]
    end

    factory :england_tour do
      league factory: %i[league england_league]
    end

    factory :germany_tour do
      league factory: %i[league germany_league]
    end

    factory :spain_tour do
      league factory: %i[league spain_league]
    end

    factory :france_tour do
      league factory: %i[league france_league]
    end

    factory :euro_tour do
      league factory: %i[league euro_league]
    end
  end
end
