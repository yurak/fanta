FactoryBot.define do
  factory :auction_bid do
    association :auction_round
    association :team
  end
end
