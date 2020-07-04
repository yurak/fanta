FactoryBot.define do
  factory :team_module do
    sequence(:name) { |i| "name#{i}" }
  end
end
