FactoryBot.define do
  factory :league do
    name { FFaker::Company.name }

    tournament { Tournament.first || association(:tournament) }
    season { Season.first || association(:season) }

    factory :active_league do
      status { :active }
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

    trait :serie_a do
      association :tournament, :serie_a
    end
  end
end
