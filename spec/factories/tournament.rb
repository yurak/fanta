FactoryBot.define do
  factory :tournament do
    sequence(:name) { FFaker::Company.name }
    sequence(:code) { FFaker::Internet.slug }

    trait :with_38_rounds do
      after(:create) do |tournament|
        (1..38).each do |number|
          create(:tournament_round, number: number, tournament: tournament)
        end
      end
    end
  end
end
