FactoryBot.define do
  factory :tournament_round do
    sequence(:number) { |i| i }

    tournament { Tournament.first || association(:tournament) }
    season { Season.last || association(:season) }

    trait :with_eurocup_tournament do
      tournament { Tournament.find_by(code: Scores::Injectors::Strategy::ECL) }
    end
  end
end
