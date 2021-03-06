FactoryBot.define do
  factory :club do
    sequence(:name) { |i| "#{FFaker::Company.name}#{i}" }
    sequence(:code) { |i| i < 99 ? "c#{i}" : i.to_s }

    association :tournament
  end
end
