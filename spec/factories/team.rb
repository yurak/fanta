FactoryBot.define do
  factory :team do
    name { FFaker::Company.name[0...18] }
    human_name { name }

    association :league
  end
end
