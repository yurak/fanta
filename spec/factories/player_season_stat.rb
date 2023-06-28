FactoryBot.define do
  factory :player_season_stat do
    association :club
    association :player
    association :season
    association :tournament
  end
end
