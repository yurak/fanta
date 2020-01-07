FactoryBot.define do
  factory :player do
    sequence(:name) { |i| "name#{i}" }
    association :team
    association :club
  end
end
