FactoryBot.define do
  factory :tournament do
    sequence(:name) { FFaker::Company.name }
    sequence(:code) { FFaker::Internet.slug }
  end
end
