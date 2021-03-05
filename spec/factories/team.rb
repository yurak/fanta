FactoryBot.define do
  factory :team do
    sequence(:name) { |i| "#{FFaker::Company.name[0...15]}#{i}" }
    human_name { name }
    sequence(:code) { |i| i < 99 ? "c#{i}" : i.to_s }

    association :league
  end
end
