FactoryBot.define do
  factory :round_player do
    association :tournament_round
    association :player
  end
end
