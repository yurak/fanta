FactoryBot.define do
  factory :join do
    user
    tournament
    team

    after(:build) do |join|
      join.auction_bid ||= build(:auction_bid, team: join.team, auction_round: nil)
    end

    before(:create) do |join|
      join.auction_bid = create(:auction_bid, team: join.team, auction_round: nil) unless join.auction_bid&.persisted?
    end

    trait :pending do
      status { :pending }
    end

    trait :approved do
      status { :approved }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end