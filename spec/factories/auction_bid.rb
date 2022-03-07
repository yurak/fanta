FactoryBot.define do
  factory :auction_bid do
    association :auction_round
    association :team

    trait :with_player_bids do
      after(:create) do |auction_bid|
        create_list(:player_bid, 5, auction_bid: auction_bid)
      end
    end
  end
end
