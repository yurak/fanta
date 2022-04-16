FactoryBot.define do
  factory :tournament_round do
    sequence(:number) { |i| i }

    tournament { Tournament.first || association(:tournament) }
    season { Season.last || association(:season) }

    trait :with_eurocup_tournament do
      tournament { Tournament.find_by(code: Scores::Injectors::Strategy::ECL) }
    end

    trait :with_serie_a_tournament do
      tournament { Tournament.find_by(code: Scores::Injectors::Strategy::CALCIO) }
    end

    trait :with_initial_matches do
      after(:create) do |tournament_round|
        create_list(:tournament_match, 2, tournament_round: tournament_round)
      end
    end

    trait :with_finished_matches do
      after(:create) do |tournament_round|
        create_list(:tournament_match, 2, tournament_round: tournament_round, host_score: 1, guest_score: 0)
      end
    end
  end
end
