FactoryBot.define do
  factory :tournament_round do
    sequence(:number) { |i| i }

    tournament
    season
  end
end
