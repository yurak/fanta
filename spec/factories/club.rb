FactoryBot.define do
  factory :club do
    sequence(:name) { |i| "name#{i}" }
    association :tournament
  end
end
