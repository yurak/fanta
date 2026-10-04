FactoryBot.define do
  factory :wishlist do
    user
    tournament
    season { Season.last || association(:season) }
    shared { false }

    trait :shared do
      shared { true }
    end
  end
end
