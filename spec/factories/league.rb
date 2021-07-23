FactoryBot.define do
  factory :league do
    name { FFaker::Company.name }

    tournament { Tournament.first || association(:tournament) }
    season { Season.first || association(:season) }

    factory :active_league do
      status { :active }
    end

    trait :serie_a_league do
      tournament { Tournament.find_by(code: 'serie_a') }
    end

    trait :epl_league do
      tournament { Tournament.find_by(code: 'epl') }
    end

    trait :bundes_league do
      tournament { Tournament.find_by(code: 'bundesliga') }
    end

    trait :laliga_league do
      tournament { Tournament.find_by(code: 'laliga') }
    end

    trait :ligue1_league do
      tournament { Tournament.find_by(code: 'ligue_1') }
    end

    trait :euro_league do
      tournament { Tournament.find_by(code: 'euro') }
    end

    trait :with_five_teams do
      after(:create) do |league|
        create_list(:team, 5, league: league)
      end
    end

    trait :with_ten_teams do
      after(:create) do |league|
        create_list(:team, 10, league: league)
      end
    end
  end
end
