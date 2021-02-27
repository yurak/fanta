FactoryBot.define do
  factory :club do
    name { FFaker::Company.name }
    code { name[0...3].upcase }

    tournament
  end
end
