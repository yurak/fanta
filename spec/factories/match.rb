FactoryBot.define do
  factory :match do
    association :tour

    host { association :team }
    guest { association :team }

    trait :with_lineups do
      after(:create) do |match|
        create(:lineup, :with_team_and_score_seven, tour: match.tour, team: match.host)
        create(:lineup, :with_team_and_score_eight, tour: match.tour, team: match.guest)
      end
    end

    trait :with_lineups_host_win do
      after(:create) do |match|
        create(:lineup, :with_team_and_score_eight, tour: match.tour, team: match.host)
        create(:lineup, :with_team_and_score_seven, tour: match.tour, team: match.guest)
      end
    end

    trait :with_lineups_draw do
      after(:create) do |match|
        create(:lineup, :with_team_and_score_seven, tour: match.tour, team: match.host)
        create(:lineup, :with_team_and_score_seven, tour: match.tour, team: match.guest)
      end
    end
  end
end
