FactoryBot.define do
  factory :match_player do
    association :round_player
    association :lineup
  end
end
