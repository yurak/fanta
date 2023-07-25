FactoryBot.define do
  factory :result do
    team
    league

    trait :with_opponents do
      after(:create) do |result|
        create(:result, league: result.league, points: 34, scored_goals: 53, missed_goals: 21)
        create(:result, league: result.league, points: 27, scored_goals: 34, missed_goals: 26)
        create(:result, league: result.league, points: 15, scored_goals: 18, missed_goals: 46)
      end
    end
  end
end
