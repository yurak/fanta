FactoryBot.define do
  factory :division do
    sequence(:level) { FFaker::Company.name[0].upcase }
    sequence(:number) { Random.rand(9) }
  end
end
