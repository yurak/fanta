FactoryBot.define do
  factory :lineup do
    association :team_module
    association :tour
    association :team
  end
end
