FactoryBot.define do
  factory :player_team do
    association :player
    association :team
  end
end
