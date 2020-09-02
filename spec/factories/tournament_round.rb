FactoryBot.define do
  factory :tournament_round do
    sequence(:number) { |i| i }

    association :tournament
    association :season
  end
end
