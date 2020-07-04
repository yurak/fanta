FactoryBot.define do
  factory :player do
    sequence(:name) { |i| "name#{i}" }
    association :club
  end
end
