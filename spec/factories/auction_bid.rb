FactoryBot.define do
  factory :auction_bid do
    association :auction_round
    association :team

    trait :with_player_bids do
      after(:create) do |auction_bid|
        create_list(:player_bid, 6, auction_bid: auction_bid)
      end
    end

    trait :with_full_player_bids do
      after(:create) do |auction_bid|
        create_list(:player_bid, Team::MAX_PLAYERS, auction_bid: auction_bid)
      end
    end

    factory :ongoing_auction_bid do
      status { :ongoing }
    end

    factory :submitted_auction_bid do
      status { :submitted }
    end

    factory :completed_auction_bid do
      status { :completed }
    end

    factory :processed_auction_bid do
      status { :processed }
    end
  end
end
