FactoryBot.define do
  factory :player_bid do
    association :auction_bid
    association :player
  end
end
