FactoryBot.define do
  factory :league do
    name { FFaker::Company.name }

    tournament { Tournament.first || association(:tournament) }
    season { Season.first || association(:season) }

    factory :active_league do
      status { :active }
    end

    factory :cloneable_league do
      cloning_status { :cloneable }
    end

    trait :italy_league do
      tournament { Tournament.find_by(code: 'italy') }
    end

    trait :england_league do
      tournament { Tournament.find_by(code: 'england') }
    end

    trait :germany_league do
      tournament { Tournament.find_by(code: 'germany') }
    end

    trait :spain_league do
      tournament { Tournament.find_by(code: 'spain') }
    end

    trait :france_league do
      tournament { Tournament.find_by(code: 'france') }
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
