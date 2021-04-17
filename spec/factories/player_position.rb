FactoryBot.define do
  factory :player_position do
    association :position
    association :player
  end
end
