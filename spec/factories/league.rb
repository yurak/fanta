FactoryBot.define do
  factory :league do
    sequence(:name) { |i| "name#{i}" }
    association :tournament
  end
end
