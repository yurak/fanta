FactoryBot.define do
  factory :result do
    association :team
    association :league
  end
end
