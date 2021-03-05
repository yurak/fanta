FactoryBot.define do
  factory :league do
    name { FFaker::Company.name }

    tournament { Tournament.first || association(:tournament) }
    season { Season.first || association(:season) }

    factory :active_league do
      status { :active }
    end

    trait :serie_a do
      association :tournament, :serie_a
    end
  end
end
