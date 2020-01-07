FactoryBot.define do
  factory :club do
    sequence(:name) { |i| "name#{i}" }
  end
end
