FactoryBot.define do
  factory :season do
    sequence(:start_year) { |i| "202#{i}" }
    sequence(:end_year) { |i| "202#{i + 1}" }
  end
end
