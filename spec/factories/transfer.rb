FactoryBot.define do
  factory :transfer do
    association :auction
    association :league
    association :player
    association :team
  end
end
