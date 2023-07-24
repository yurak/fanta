FactoryBot.define do
  factory :auction_round do
    auction

    factory :processing_auction_round do
      status { :processing }
    end

    factory :closed_auction_round do
      status { :closed }
    end
  end
end
