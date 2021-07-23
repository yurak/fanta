FactoryBot.define do
  factory :transfer do
    association :league
    association :player
    association :team
  end
end
