FactoryBot.define do
  factory :match_player do
    association :player
    association :lineup
  end
end
